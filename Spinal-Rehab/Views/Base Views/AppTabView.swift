//
//  TabView.swift
//  Spinal-Rehab
//
//  Created by Hari Dass Khalsa on 6/15/26.
//

import SwiftUI

struct AppTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContentView()
            }
                .tabItem {
                    Label("Patients", systemImage: "house")
                }
            NavigationStack {
                TestDataView()
                    .navigationTitle("Test Data")
            }
                    .tabItem {
                        Label("Data", systemImage: "chart.bar.fill")
                    }
            NavigationStack {
                ExerciseListView()
                    .navigationTitle("Exercises")
            }
                    .tabItem {
                        Label("Exercises", systemImage: "figure.strengthtraining.functional")
                    }
            NavigationStack {
                MacReportTemplateEditor()
                    .navigationTitle("Report Template")
            }
                    .tabItem {
                        Label("Template", systemImage: "doc.text")
                    }


        }
    }
}

#Preview {
  //  TabView()
}
