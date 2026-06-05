import SwiftUI
import CoreGraphics // Import Core Graphics

@MainActor
func createPDF(theView: some View, fileName: String, landscape: Bool = false) -> URL? {
    // 1. Decide where to save the PDF file
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    let outputURL = documentsDirectory.appendingPathComponent("\(fileName)").appendingPathExtension("pdf")

    // 2. Define the size of the PDF page (e.g., US Letter)
    
    var pageSize = CGRect(x: 0, y: 0, width: 612, height: 792) // 72 DPI for US Letter
    if landscape {
        pageSize = CGRect(x: 0, y: 0, width: 792, height: 612)
    }

    // 3. Create the CGContext for the PDF
    guard let pdfContext = CGContext(outputURL as CFURL, mediaBox: &pageSize, nil) else {
        return nil
    }

    // 4. Instantiate the ImageRenderer with your SwiftUI view
    let renderView =  theView
    let renderer = ImageRenderer(content: renderView)

    // 5. Render the content into the PDF context
    pdfContext.beginPDFPage(nil)
    renderer.render { size, context in
        // The `context` here is a SwiftUI GraphicsContext.
     // The closure automatically handles the rendering onto the pdfContext
        context(pdfContext)
    }
    pdfContext.endPDFPage()
    pdfContext.closePDF()

    print("PDF saved to: \(outputURL.path)")
    return outputURL
}
