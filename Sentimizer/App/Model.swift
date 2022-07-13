//
//  Model.swift
//  Sentimizer
//
//  Created by Samuel Ginsberg on 11.07.22.
//

import Foundation
import CoreData
import SwiftUI

class Model: ObservableObject {
    @StateObject private var persistenceController = PersistenceController()
    
    @Published var influenceImprovedMonth: ([String], [Double]) = ([], [])
    @Published var influenceImprovedYear: ([String], [Double]) = ([], [])
    @Published var influenceWorsenedMonth: ([String], [Double]) = ([], [])
    @Published var influenceWorsenedYear: ([String], [Double]) = ([], [])
    
    init() {
        let influenceMonth = PersistenceController.getInfluence(with: K.monthInfluence)
        let influenceYear = PersistenceController.getInfluence(with: K.yearInfluence)
        
        influenceImprovedMonth = influenceMonth.0
        influenceWorsenedMonth = influenceMonth.1
        influenceImprovedYear = influenceYear.0
        influenceWorsenedYear = influenceYear.1
    }
    
    func updateInfluence(activities: FetchedResults<Activity>, _ viewContext: NSManagedObjectContext) {
        DispatchQueue.global(qos: .userInitiated).async {
            let monthInfluence = StatisticsData.getInfluence(viewContext: viewContext, interval: K.timeIntervals[2], activities: activities)
            let yearInfluence = StatisticsData.getInfluence(viewContext: viewContext, interval: K.timeIntervals[3], activities: activities)
            DispatchQueue.main.async {
                self.influenceImprovedMonth = monthInfluence.0
                self.influenceWorsenedMonth = monthInfluence.1
                self.persistenceController.saveInfluence(with: K.monthInfluence, data: monthInfluence)
                
                self.influenceImprovedYear = yearInfluence.0
                self.influenceWorsenedYear = yearInfluence.1
                self.persistenceController.saveInfluence(with: K.yearInfluence, data: yearInfluence)
            }
        }
    }
}
