//
//  ContentView.swift
//  Sentimizer
//
//  Created by Samuel Ginsberg, 2022.
//

import SwiftUI
import CoreData

struct MainActivityView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    
    @StateObject private var persistenceController = PersistenceController()
    
    @State private var welcomeScreenPresented = false
    @State private var addActivitySheetPresented = false
    
    @State private var selectedMonth = Date()
    
    @State private var entryDays: [String] = []
    @State private var entryContent: [[ActivityData]] = []
    
    @State private var showLastMonth = false
    
    @FetchRequest(sortDescriptors: [], predicate: nil) private var entries: FetchedResults<Entry>
    
    @State private var brandColor2 = Color.brandColor2
    @State private var brandColor2Light = Color.brandColor2Light
    
    let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ScrollView {
            MonthSwitcher(selectedMonth: $selectedMonth, allowFuture: false)
                .padding(.bottom)
            
            Greeting()
            
            Group {
                AddActivityButton(addActivitySheetPresented: $addActivitySheetPresented)
                
                if entries.count < 1 {
                    NoEntries()
                } else {
                    WhatNext(activity: "Walk")
                        .padding(.bottom, 15)
                        .padding(.horizontal, 5)
                    
                    if persistenceController.getEntryData(entries: entries, month: selectedMonth, viewContext).0.count < 1  {
                        NoEntriesThisMonth()
                        
                        let lastMonth = Date.appendMonths(to: selectedMonth, count: -1)
                        if persistenceController.getEntryData(entries: entries, month: lastMonth, viewContext).0.count > 0 {
                            LastMonthTitle(selectedMonth: selectedMonth)
                                .onAppear {
                                    showLastMonth = true
                                }
                        }
                    }
                    
                    ForEach(0..<entryDays.count, id: \.self) { index in
                        EntriesOfDay(day: entryDays[index], entries: entryContent[index])
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $addActivitySheetPresented) {
            AddActivityView()
                .environment(\.managedObjectContext, self.viewContext)
        }
        .onAppear {
            Task {
                do {
                    var db = DataBridge()
                    try await db.getAndPost(userId: UserDefaults.standard.string(forKey: K.userId) ?? "")
                } catch {
                    print(error)
                }
            }
            
            fillEntryData()
            welcomeScreenPresented = !UserDefaults.standard.bool(forKey: K.welcomeScreenShown)
            
            brandColor2 = Color.brandColor2
            brandColor2Light = Color.brandColor2Light
        }
        .onChange(of: addActivitySheetPresented) { newValue in
            if !newValue {
                if persistenceController.getEntryData(entries: entries, month: selectedMonth, viewContext).0.count > 0 {
                    showLastMonth = false
                }
                
                fillEntryData()
            }
        }
        .onChange(of: selectedMonth) { newValue in
            showLastMonth = false
            fillEntryData()
        }
        .onChange(of: showLastMonth) { newValue in
            fillEntryData()
        }
        .fullScreenCover(isPresented: $welcomeScreenPresented) {
            WelcomeView()
        }
    }
    
    init() {
        let f:NSFetchRequest<Entry> = Entry.fetchRequest()
        f.sortDescriptors = [NSSortDescriptor(key: #keyPath(Entry.date), ascending: false)]
        _entries = FetchRequest(fetchRequest: f)
    }
    
    func fillEntryData() {
        var dateComponent = DateComponents()
        if showLastMonth {
            dateComponent.month = -1
        } else {
            dateComponent.month = 0
        }
        
        (entryDays, entryContent) = persistenceController.getEntryData(entries: entries, month: Calendar.current.date(byAdding: dateComponent, to: selectedMonth) ?? Date.distantPast, viewContext)
    }
}

struct Greeting: View {
    @AppStorage(K.userNickname) var userNickname: String = ""
    
    @State private var brandColor2 = Color.brandColor2
    @State private var brandColor2Light = Color.brandColor2Light
    
    var body: some View {
        HStack {
            let tOD = Date.getTimeOfDay()
            Text("\(Image(systemName: K.symbolForTimeOfDay(tOD))) Good \(K.stringForTimeOfDay(tOD)), \(userNickname)")
                .font(.senti(size: 25))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .gradientForeground(colors: [brandColor2, brandColor2Light])
                .padding(.horizontal)
                .padding(.bottom)
            Spacer()
        }
        .onAppear {
            brandColor2 = Color.brandColor2
            brandColor2Light = Color.brandColor2Light
        }
    }
}

struct AddActivityButton: View {
    @Binding var addActivitySheetPresented: Bool
    
    let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(alignment: .leading) {
            SentiButton(icon: "plus.circle", title: "Add Activity")
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .onTapGesture {
                    addActivitySheetPresented = true
                    
                    haptic.impactOccurred()
                }
        }
        .padding(.horizontal, 5)
        .padding(.bottom)
    }
}

struct NoEntries: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "figure.walk")
                Image(systemName: "fork.knife")
                Image(systemName: "briefcase.fill")
            }
            .font(.title)
            Text("Create Your First Activity Above")
                .font(.senti(size: 15))
                .bold()
                .padding()
        }
        .padding(.top, 50)
    }
}

struct NoEntriesThisMonth: View {
    var body: some View {
        Text("\(Image(systemName: "list.bullet.below.rectangle")) There are no entries in the chosen month.")
            .font(.senti(size: 15))
            .bold()
            .padding()
    }
}

struct LastMonthTitle: View {
    let selectedMonth: Date
    
    var body: some View {
        Text(Calendar.current.monthSymbols[Calendar.current.component(.month, from: selectedMonth)-2] + " \(Calendar.current.component(.year, from: selectedMonth))")
            .font(.senti(size: 20))
            .minimumScaleFactor(0.8)
            .padding()
    }
}

struct EntriesOfDay: View {
    let day: String
    let entries: [ActivityData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey(day))
                .font(.senti(size: 25))
                .padding()
            
            ForEach(0 ..< entries.count, id: \.self) { i in
                let activity = entries[i]
                let time = DateFormatter.formatDate(date: activity.date, format: "HH:mm")
                
                NavigationLink { ActivityDetailView(activity: activity, day: LocalizedStringKey(day), time: time) } label: {
                    ActivityBar(activity: activity, activityName: LocalizedStringKey(activity.activity), time: time)
                        .padding([.bottom, .trailing], 10)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 25).foregroundColor(.dayViewBgColor).shadow(color: .gray.opacity(0.3), radius: 5))
        .padding(.vertical, 5)
        .padding(.bottom)
    }
}

struct MainActivityView_Previews: PreviewProvider {
    static var previews: some View {
        MainActivityView()
    }
}
