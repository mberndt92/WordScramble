//
//  ContentView.swift
//  WordScramble
//
//  Created by Maximilian Berndt on 2023/03/14.
//

import SwiftUI

struct ContentView: View {
    
    enum FocusedField {
        case enterWord
    }
    
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @FocusState private var focusedField: FocusedField?
    
    private var score: Int {
        let wordCount = usedWords.count
        let characterCount = usedWords
            .map({ $0.count })
            .reduce(0, +)
        return wordCount + characterCount
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .enterWord)
                        .onSubmit {
                            addNewWord()
                            focusedField = .enterWord
                        }
                }
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onAppear(perform: startGame)
            .onAppear {
                focusedField = .enterWord
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    Text("Score: \(score)")
                })
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button("New Game", action: startGame)
                })
            })
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addNewWord() {
        let answer = newWord
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard answer != rootWord else {
            wordError(title: "Reused word", message: "You can't just take the given word and make it look like your own")
            return
        }
        
        guard answer.count >= 3 else {
            wordError(title: "Too  short", message: "You need at least three characters to build a word in this game")
            return
        }
        
        guard answer.count > 0 else {
            wordError(title: "Empty word", message: "That's just empty!")
            return
        }
        
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original!")
            return
        }
        
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell '\(answer)' from '\(rootWord)'")
            return
        }
        
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    
    private func isOriginal(word: String) -> Bool {
        usedWords.contains(word) == false
    }
    
    private func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    private func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: "en"
        )
        
        return misspelledRange.location == NSNotFound
    }
    
    private func startGame() {
        usedWords = []
        if let startWordUrl = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordUrl) {
                let allWords = startWords.components(separatedBy: "\n")
                rootWord = allWords.randomElement() ?? "silkworm"
                return
            }
        }
        fatalError("Could not load start.txt from bundle")
    }
    
    private func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
