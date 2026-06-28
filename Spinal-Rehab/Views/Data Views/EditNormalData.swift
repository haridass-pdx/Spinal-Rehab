//
//  EditNormalData.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/27/26.
//

import SwiftUI

/*
 var id: Int = 0
 var mean: Int = 0
 var excellent: Int = 0
 var good: Int = 0
 var fair: Int = 0
 var poor: Int = 0
 var verypoor: Int = 0
 var gender: String = ""
 var agerange: String = ""
 var lowage: Int = 0
 var highage: Int = 0
 var normid: Int = 0
 var testtable_id: Int = 0
 
 */

struct EditNormalData: View {
    @Binding var normData: normalData
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 30.0){
            Text("Normal Data \(normData.id)")
                .font(.title)
            Text("Text Table ID: \(normData.testtable_id)")
                .font(.title2)
            Form{
                TextField("Gender", text: $normData.gender)
                TextField("Age Range",text: $normData.agerange)
                TextField("Low Age", value: $normData.lowage, format: .number)
                TextField("High Age", value: $normData.highage, format: .number)
                TextField("Mean", value: $normData.mean, format: .number)
                TextField("Excellent", value: $normData.excellent, format: .number)
                TextField("Good", value: $normData.good, format: .number)
                TextField("Fair", value: $normData.fair, format: .number)
                TextField("Poor", value: $normData.poor, format: .number)
                TextField("Very Poor", value: $normData.verypoor, format: .number)
   
    
    
                
                HStack{
                    Button("Save"){
                        Task{
                            await saveRecord()
                        }
                        dismiss()

                        
                    }
                    Button("Cancel"){
                        dismiss()

                        
                    }
                    
                }
                
            }
        }
        .frame(width: 400.0)
    }
    
    func saveRecord() async{
        var localRec = normData
        await localRec.saveRec()
        normData = localRec
    }
}

#Preview {
    // EditNormalData()
}
