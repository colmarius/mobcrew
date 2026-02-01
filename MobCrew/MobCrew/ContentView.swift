import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    
    var body: some View {
        Group {
            if appState.isOnBreak {
                BreakScreenView(appState: appState)
            } else {
                HSplitView {
                    timerSection
                        .frame(minWidth: 200, maxWidth: 300)
                    
                    RosterView(roster: appState.roster)
                        .frame(minWidth: 250)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 450)
    }
    
    private var timerSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            rolesDisplay
            
            timerDisplay
            
            timerControls
            
            durationStepper
            
            if appState.showTips && appState.timerState.isRunning {
                TipView(tip: appState.currentTip)
                    .frame(maxHeight: 120)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var rolesDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let driver = appState.roster.driver {
                HStack {
                    Text("Driver")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    Text(driver.name)
                        .font(.title3)
                }
            }
            
            if let navigator = appState.roster.navigator {
                HStack {
                    Text("Navigator")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(Capsule())
                    Text(navigator.name)
                        .font(.title3)
                }
            }
        }
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(appState.timerState.displayTime)
                .font(.system(size: 64, weight: .light, design: .monospaced))
                .foregroundStyle(appState.timerState.isRunning ? .primary : .secondary)
            
            ProgressView(value: appState.timerState.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 200)
            
            BreakProgressView(
                breakInterval: appState.breakInterval,
                turnsSinceBreak: appState.turnsSinceBreak
            )
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
        }
    }
    
    private var timerControls: some View {
        HStack(spacing: 16) {
            Button(action: { appState.toggleTimer() }) {
                Image(systemName: appState.timerState.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            
            Button(action: { appState.resetTimer() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)
            
            Button(action: { appState.skipTurn() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.bordered)
            .disabled(appState.roster.activeMobsters.count < 2)
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
    
    private var durationStepper: some View {
        HStack {
            Text("Duration:")
            Stepper(
                value: Binding(
                    get: { appState.timerDuration / 60 },
                    set: { newMinutes in
                        appState.timerDuration = newMinutes * 60
                        if !appState.timerState.isRunning {
                            appState.resetTimer()
                        }
                    }
                ),
                in: 1...30
            ) {
                Text("\(appState.timerDuration / 60) min")
                    .monospacedDigit()
            }
        }
        .font(.callout)
    }
}

#Preview {
    ContentView(appState: AppState())
        .frame(width: 600, height: 450)
}
