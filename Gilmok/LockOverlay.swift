import SwiftUI
import UIKit

enum LockText {
    static func hint(_ language: AppLanguage) -> String {
        switch language {
        case .en: "Drag the lock icon left or right to unlock"
        case .ja: "ロックアイコンを左右にドラッグして解除してください"
        case .zh: "左右拖动锁图标即可解锁"
        case .fr: "Faites glisser le cadenas vers la gauche ou la droite pour déverrouiller"
        case .pt: "Arraste o cadeado para a esquerda ou direita para desbloquear"
        case .es: "Arrastra el candado a la izquierda o derecha para desbloquear"
        case .ko: "잠금 아이콘을 좌우로 밀면 해제됩니다"
        }
    }

    static func level(_ language: AppLanguage, _ level: Int) -> String {
        switch language {
        case .en: "Level \(level)"
        case .ja: "段階 \(level)"
        case .zh: "等级 \(level)"
        case .fr: "Niveau \(level)"
        case .pt: "Nível \(level)"
        case .es: "Nivel \(level)"
        case .ko: "단계 \(level)"
        }
    }

    static func battery(_ language: AppLanguage, _ percent: Int) -> String {
        switch language {
        case .en: "Battery \(percent)%"
        case .ja: "バッテリー \(percent)%"
        case .zh: "电量 \(percent)%"
        case .fr: "Batterie \(percent)%"
        case .pt: "Bateria \(percent)%"
        case .es: "Batería \(percent)%"
        case .ko: "배터리 \(percent)%"
        }
    }
}

struct LockOverlay: View {
    let language: AppLanguage
    let onUnlock: () -> Void

    @AppStorage("gilmok_lock_level") private var level = 2
    @State private var drag = CGSize.zero
    @State private var dragging = false

    private let dimAlpha: [Double] = [0.55, 0.75, 0.9]
    private let iconSize: CGFloat = 96

    var body: some View {
        GeometryReader { geo in
            let iconCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.42)
            let unlockDistance = min(geo.size.width * 0.22, 110)
            ZStack {
                Color.black.opacity(dimAlpha[min(max(level, 1), 3) - 1])
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {}

                VStack {
                    HStack(alignment: .top) {
                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(timeText(timeline.date))
                                    .font(.system(size: 56, weight: .bold))
                                Text(dateText(timeline.date))
                                    .font(.system(size: 18))
                            }
                        }
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 1)) { _ in
                            if let percent = batteryPercent() {
                                Text(LockText.battery(language, percent))
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.18), in: Capsule())
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    Spacer()
                }

                Text(LockText.hint(language))
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .position(x: geo.size.width / 2, y: iconCenter.y + iconSize / 2 + 48)

                Image(systemName: "chevron.left")
                    .font(.system(size: 30, weight: .bold))
                    .opacity(0.6)
                    .position(x: iconCenter.x - iconSize / 2 - 36, y: iconCenter.y)
                Image(systemName: "chevron.right")
                    .font(.system(size: 30, weight: .bold))
                    .opacity(0.6)
                    .position(x: iconCenter.x + iconSize / 2 + 36, y: iconCenter.y)

                Image(systemName: "lock.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFBBF24))
                    .frame(width: iconSize, height: iconSize)
                    .background(Color.white.opacity(dragging ? 0.4 : 0.25), in: Circle())
                    .position(x: iconCenter.x + drag.width, y: iconCenter.y)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragging = true
                                drag = CGSize(width: value.translation.width, height: 0)
                            }
                            .onEnded { _ in
                                dragging = false
                                if abs(drag.width) >= unlockDistance {
                                    onUnlock()
                                } else {
                                    withAnimation(.easeOut(duration: 0.2)) { drag = .zero }
                                }
                            }
                    )

                VStack(spacing: 6) {
                    Button {
                        level = level % 3 + 1
                    } label: {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 26))
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.25), in: Circle())
                    }
                    .buttonStyle(.plain)
                    Text(LockText.level(language, min(max(level, 1), 3)))
                        .font(.system(size: 14, weight: .semibold))
                }
                .position(x: 24 + 30, y: geo.size.height - geo.safeAreaInsets.bottom - 120)
            }
            .foregroundStyle(.white)
        }
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.setLocalizedDateFormatFromTemplate("MMMMdEEEE")
        return formatter.string(from: date)
    }

    private func batteryPercent() -> Int? {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let value = UIDevice.current.batteryLevel
        return value < 0 ? nil : Int((value * 100).rounded())
    }
}
