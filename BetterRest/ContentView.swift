//
//  ContentView.swift
//  BetterRest
//

import CoreML
import SwiftUI

func hourFormat(_ hours: Double) -> String
{
    let fraction = hours.truncatingRemainder(dividingBy: 1)
    let mins = Int((fraction * 60).rounded(.down))
    let hrs = Int(hours - fraction)
    
    var hourPart = "\(hrs)"
    if (hrs != 11) && (hrs % 10 == 1) {
        hourPart += " hour"
    } else {
        hourPart += " hours"
    }
    
    var minPart = ""
    
    if (mins != 0) {
        minPart = "\(mins)"
        if (mins != 11) && (mins % 10 == 1) {
            minPart += " minute"
        } else {
            minPart += " minutes"
        }
    }
    
    return "\(hourPart) \(minPart)"
}

struct ContentView: View {
    static let defaultSleepHours = 8
    @State private var sleepHours = Double(defaultSleepHours)
    @State private var wakeUp = defaultWakeTime
    @State private var coffeeCups = 1
    
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    var calculatedBedtime: Date {
        do {
            let configuration = MLModelConfiguration()
            let model = try SleepHoursPredictor(configuration: configuration)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let seconds = 3600 * hour + minute * 60
            let prediction = try model.prediction(input: .init(wake: Double(seconds), estimatedSleep: sleepHours, coffee: Double(coffeeCups)))
            let bedTime = wakeUp.addingTimeInterval(-prediction.actualSleep)

            return bedTime
        } catch {
            alertTitle = "Error"
            alertMessage = "Could not calculate the bedtime"
            showingAlert = true
            return Date.now
        }
    }
    
    func calculateBedtime()
    {
        do {
            let configuration = MLModelConfiguration()
            let model = try SleepHoursPredictor(configuration: configuration)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let seconds = 3600 * hour + minute * 60
            let prediction = try model.prediction(input: .init(wake: Double(seconds), estimatedSleep: sleepHours, coffee: Double(coffeeCups)))
            let bedTime = wakeUp.addingTimeInterval(-prediction.actualSleep)
            
            alertTitle = "Your bedtime is..."
            alertMessage = bedTime.formatted(date: .omitted, time: .shortened)
        } catch {
            alertTitle = "Error"
            alertMessage = "Could not calculate the bedtime"
        }
        
        showingAlert = true
    }
    
    func tomorrow() -> Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: DateComponents(day: 1), to: Date())!)
    }
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = defaultSleepHours
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "sun.max")
                            .foregroundColor(.accentColor)
                        Text("When would you like to wake up?")
                            .font(.headline)
                    }
                    
                    DatePicker("Please enter a time:", selection: $wakeUp,
                       displayedComponents: .hourAndMinute)
                }
                
                
                Section {
                    HStack {
                        Image(systemName: "bed.double")
                            .foregroundColor(.accentColor)
                        Text("Desired amount of sleep")
                    }
                    
                    Stepper("\(hourFormat(sleepHours))", value: $sleepHours, in: 4...12, step: 0.5)
                }
                
                Section {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(.accentColor)
                        Text("Daily coffee intake")
                            .font(.headline)
                    }
                    
                    Picker("Cups a day", selection: $coffeeCups) {
                        ForEach(0..<21) {
                            numCups in
                            Text(numCups == 1 ? "1 cup" : "\(numCups) cups")
                        }
                    }
                    
                } footer: {
                    Text("Each cup of coffee increases required sleep time by around 30 minutes")
                }
                
                Section {
                    Text("\(calculatedBedtime.formatted(date: .omitted, time: .shortened))")
                        .font(.headline)
                } header: {
                    Text("Your recommended bedtime is:")
                }
            }
            .navigationTitle("BetterRest")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
