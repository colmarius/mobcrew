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
            
            if appState.showTips && appState.isRunning {
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Driver")
                .accessibilityValue(driver.name)
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Navigator")
                .accessibilityValue(navigator.name)
            }
        }
    }
    
    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(appState.timerState.displayTime)
                .font(.system(.largeTitle, design: .monospaced, weight: .light))
                .fontWeight(.light)
                .foregroundStyle(appState.isRunning ? .primary : .secondary)
                .accessibilityLabel(appState.timerAccessibilityLabel)
                .accessibilityValue(appState.timerAccessibilityValue)
                .accessibilityHint(appState.timerAccessibilityHint)
            
            ProgressView(value: appState.timerState.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 200)
                .accessibilityHidden(true)
            
            if appState.breaksEnabled {
                BreakProgressView(
                    breakInterval: appState.breakInterval,
                    turnsSinceBreak: appState.turnsSinceBreak
                )
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
    
    private var timerControls: some View {
        HStack(spacing: 16) {
            Button(action: { appState.performPrimaryAction() }) {
                Image(systemName: appState.primaryActionSystemImage)
                    .font(.title)
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!appState.canPerformPrimaryAction)
            .help(appState.primaryActionLabel)
            .accessibilityLabel(appState.primaryActionAccessibilityLabel)
            .accessibilityHint(appState.primaryActionAccessibilityHint)
            .keyboardShortcut(.return, modifiers: .command)
            
            Button(action: { appState.resetTimer() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!appState.canResetTimer)
            .help("Reset Timer")
            .accessibilityLabel("Reset turn timer")
            .accessibilityHint(appState.resetTimerAccessibilityHint)
            
            Button(action: { appState.performSkipAction() }) {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!appState.canPerformSkipAction)
            .help(appState.skipActionLabel)
            .accessibilityLabel(appState.skipActionAccessibilityLabel)
            .accessibilityHint(appState.skipActionAccessibilityHint)
            .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
    
    private var durationStepper: some View {
        HStack {
            Text("Duration:")
            Stepper(
                value: Binding(
                    get: { appState.timerDuration / 60 },
                    set: { appState.setTimerDuration(minutes: $0) }
                ),
                in: AppState.timerDurationMinutesRange
            ) {
                Text("\(appState.timerDuration / 60) min")
                    .monospacedDigit()
            }
            .accessibilityLabel("Turn duration")
            .accessibilityValue("\(appState.timerDuration / 60) minutes")
            .accessibilityHint("Changes the configured duration. An active or paused turn keeps its current progress.")
        }
        .font(.callout)
    }
}

#Preview {
    ContentView(appState: AppState())
        .frame(width: 600, height: 450)
}
