import Foundation

struct SavedGame {
    let stage: Int
    let wave: Int
    let state: String
}

enum SavedGameStore {
    private static let key = "gilmok_saved_game"

    static func save(stage: Int, wave: Int, state: String) {
        let payload: [String: Any] = ["stage": stage, "wave": wave, "state": state]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> SavedGame? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stage = jsonInt(payload["stage"]),
              let wave = jsonInt(payload["wave"]),
              let state = payload["state"] as? String else { return nil }
        return SavedGame(stage: stage, wave: wave, state: state)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

enum SaveText {
    static func title(_ language: AppLanguage) -> String {
        switch language {
        case .en: "Saved game found"
        case .ja: "保存されたゲームがあります"
        case .zh: "发现存档"
        case .fr: "Partie sauvegardée"
        case .pt: "Jogo salvo encontrado"
        case .es: "Partida guardada"
        case .ko: "저장된 게임이 있습니다"
        }
    }

    static func message(_ language: AppLanguage, stage: Int, wave: Int) -> String {
        switch language {
        case .en: "Stage \(stage), wave \(wave). Continue where you left off?"
        case .ja: "ステージ \(stage)、ウェーブ \(wave)。続きから始めますか?"
        case .zh: "第 \(stage) 关,第 \(wave) 波。要继续上次的游戏吗?"
        case .fr: "Niveau \(stage), vague \(wave). Reprendre la partie ?"
        case .pt: "Fase \(stage), onda \(wave). Continuar de onde parou?"
        case .es: "Fase \(stage), oleada \(wave). ¿Continuar donde lo dejaste?"
        case .ko: "스테이지 \(stage), 웨이브 \(wave) 에서 멈췄습니다. 이어서 하시겠습니까?"
        }
    }

    static func resume(_ language: AppLanguage) -> String {
        switch language {
        case .en: "Continue"
        case .ja: "続きから"
        case .zh: "继续"
        case .fr: "Reprendre"
        case .pt: "Continuar"
        case .es: "Continuar"
        case .ko: "이어하기"
        }
    }

    static func newGame(_ language: AppLanguage) -> String {
        switch language {
        case .en: "New game"
        case .ja: "新しく始める"
        case .zh: "新游戏"
        case .fr: "Nouvelle partie"
        case .pt: "Novo jogo"
        case .es: "Nueva partida"
        case .ko: "새로 하기"
        }
    }
}

func jsonInt(_ value: Any?) -> Int? {
    if let number = value as? Int { return number }
    if let number = value as? NSNumber { return number.intValue }
    return nil
}

func jsonFloat(_ value: Any?) -> Float? {
    if let number = value as? Double { return Float(number) }
    if let number = value as? NSNumber { return number.floatValue }
    return nil
}

func jsonBool(_ value: Any?) -> Bool? {
    if let flag = value as? Bool { return flag }
    if let number = value as? NSNumber { return number.boolValue }
    return nil
}

func saveName<T>(_ value: T) -> String {
    String(describing: value)
}

func weaponKind(named name: String) -> WeaponKind? {
    switch name {
    case "basic": return .basic
    case "shotgun": return .shotgun
    case "laser": return .laser
    case "bomb": return .bomb
    case "emp": return .emp
    case "poison": return .poison
    default: return nil
    }
}

func enemyKind(named name: String) -> EnemyKind? {
    switch name {
    case "normal": return .normal
    case "dog": return .dog
    case "robot": return .robot
    case "tank": return .tank
    case "ufo": return .ufo
    default: return nil
    }
}
