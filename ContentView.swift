import SwiftUI
import AudioKit
import AVFoundation
import AVFAudio

class DrumClass : ObservableObject {
    let engine = AudioEngine()
    var instrument = AppleSampler()
    @Published var playing : [Bool] = Array(repeating: false, count: 16)
    let notes = [36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51]
    let names = ["KICK", "SNARE", "CLOSED HI-HAT", "OPEN HI-HAT", "RIM SHOT", "CRASH", "TOM I", "TOM II", "PAD I", "PAD II", "PAD III", "PAD IV", "PAD V", "PAD VI", "PAD VII", "PAD VIII"]
    var files: [AVAudioFile] = []
    
    init() {
        engine.output = instrument
        loadFiles()
        loadInstrument()
        try? engine.start()
    }
    
    func getNote (pitch: Int) -> String {
        let noteName: [String] = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        return noteName[pitch % 12] + String((pitch - 12) / 12)
    }
    
    func loadFiles() {
        do {
            var idx = 36
            for name in names {
                print (name + getNote(pitch: idx))
                
                if let fileURL = Bundle.main.url (forResource: name+getNote(pitch: idx), withExtension: "wav") {
                    let audioFile = try AVAudioFile (forReading: fileURL)
                    files.append (audioFile)
                } else {
                    print ("Could not find file \(name + getNote(pitch: idx))")
                }
                idx += 1        
            }
            print ("\(files.count)")
        } catch {
            print ("Could not load file")
        }
    }
    
    func loadInstrument() {
        do {
            try instrument.loadAudioFiles (files)
        } catch {
            print("Failed loading instrument")
        }
    }
}

struct DrumView: Identifiable, View {
    @EnvironmentObject var conductor: DrumClass
    var id: Int
    var body: some View {
        RoundedRectangle(cornerRadius: 20.0)
            .fill(conductor.playing[id] ? Color.indigo.opacity(0.5) :Color.blue.opacity(0.5))
            .aspectRatio(contentMode: .fit)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in
                    if !conductor.playing[id] {
                        conductor.playing[id] = true
                        conductor.instrument.play(noteNumber: MIDINoteNumber(conductor.notes[id]), velocity: 90, channel: 10)
                        print("play \(id)") 
                    }
                }
                .onEnded { _ in
                    conductor.playing[id] = false
                    conductor.instrument.stop(noteNumber: MIDINoteNumber(conductor.notes[id]), channel: 10)
                    print("end \(id)")
                })
            .overlay{
                Text(conductor.names[id]).allowsHitTesting(false)
            }
    }
}

struct ContentView: View {
    @StateObject var conductor = DrumClass()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors:[.blue.opacity(0.5), .black]), center: .center, startRadius: 2, endRadius: 650)
                .edgesIgnoringSafeArea(.all)
            VStack {
                ForEach(0..<4) { x in
                    HStack {
                        ForEach(0..<4) { y in
                            DrumView(id: y + x * 4)
                        }
                    }
                }
            }.padding(10)
        }.environmentObject(conductor)
    }
}
