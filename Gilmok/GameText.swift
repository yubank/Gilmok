import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case en, ja, zh, fr, pt, es, ko

    var id: String { rawValue }

    var title: String {
        switch self {
        case .en: "English"
        case .ja: "日本語"
        case .zh: "中文"
        case .fr: "Français"
        case .pt: "Português"
        case .es: "Español"
        case .ko: "한국어"
        }
    }

    static func load() -> AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "gilmok_language") ?? "") ?? .en
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: "gilmok_language")
    }
}

struct GameCopy {
    let routeDefense: String
    let pressAnywhere: String
    let missionBriefing: String
    let stageWord: String
    let allComplete: String
    let createdBy: String
    let backToTitle: String
    let settings: String
    let soundEffects: String
    let backgroundMusic: String
    let audioNote: String
    let done: String
    let back: String
    let language: String
    let lives: String
    let gold: String
    let mines: String
    let mine: String
    let retry: String
    let recallWord: String
    let bossWord: String
    let waveWord: String
    let bossIncoming: String
    let basic: String
    let shotgun: String
    let laser: String
    let bomb: String
    let emp: String
    let poison: String
    let basicHint: String
    let shotgunHint: String
    let laserHint: String
    let bombHint: String
    let empHint: String
    let poisonHint: String
    let briefings: [String]
    let cleared: String
    let defeated: String
    let repairing: String
    let maxLevel: String
    let bossHintText: String
    let craft: String
    private let stageLineFormat: String
    private let recallFormat: String
    private let waveFormat: String
    private let minePlaceFormat: String
    private let durabilityFormat: String
    private let upgradingFormat: String
    private let mergeFormat: String
    private let upgradeFormat: String
    private let recalledFormat: String
    private let mineMax: String
    private let mineUpgradeFormat: String

    static var current = GameCopy.make(.en)

    static func use(_ language: AppLanguage) {
        current = make(language)
    }

    func weaponLabel(_ kind: WeaponKind) -> String {
        switch kind {
        case .basic: basic
        case .shotgun: shotgun
        case .laser: laser
        case .bomb: bomb
        case .emp: emp
        case .poison: poison
        }
    }

    func weaponHint(_ kind: WeaponKind) -> String {
        switch kind {
        case .basic: basicHint
        case .shotgun: shotgunHint
        case .laser: laserHint
        case .bomb: bombHint
        case .emp: empHint
        case .poison: poisonHint
        }
    }

    func stageLine(_ stage: Int) -> String { String(format: stageLineFormat, stage) }
    func recall(_ refund: Int) -> String { refund > 0 ? String(format: recallFormat, refund) : recallWord }
    func wave(_ number: Int) -> String { String(format: waveFormat, number) }
    func minePlace(level: Int, hit: Int, splash: Int) -> String { String(format: minePlaceFormat, level, hit, splash) }
    func durability(now: Int, max: Int) -> String { String(format: durabilityFormat, now, max) }
    func upgrading(next: Int) -> String { String(format: upgradingFormat, next) }
    func merge(hint: String, level: Int, next: Int) -> String { String(format: mergeFormat, hint, level, next) }
    func upgrade(hint: String, cost: Int) -> String { String(format: upgradeFormat, hint, cost) }
    func recalled(stage: Int) -> String { String(format: recalledFormat, stage) }
    func mineAccess(maxed: Bool, cost: Int) -> String { maxed ? mineMax : String(format: mineUpgradeFormat, cost) }

    static func make(_ language: AppLanguage) -> GameCopy {
        switch language {
        case .en: en
        case .ja: ja
        case .zh: zh
        case .fr: fr
        case .pt: pt
        case .es: es
        case .ko: ko
        }
    }

    private static let en = pack(
        routeDefense: "TACTICAL ROUTE DEFENSE",
        pressAnywhere: "Press any where ...",
        missionBriefing: "MISSION BRIEFING",
        stageWord: "STAGE",
        allComplete: "ALL MISSIONS COMPLETE",
        createdBy: "CREATED BY",
        backToTitle: "BACK TO TITLE",
        settings: "Settings",
        soundEffects: "Sound Effects",
        backgroundMusic: "Background Music",
        audioNote: "Sound effects and background music can be controlled independently.",
        done: "Done",
        back: "BACK",
        language: "Language",
        lives: "Lives",
        gold: "Gold",
        mines: "Mines",
        mine: "Mine",
        retry: "Retry",
        recallWord: "Recall",
        bossWord: "BOSS",
        waveWord: "WAVE",
        bossIncoming: "BOSS INCOMING",
        basic: "Basic",
        shotgun: "Shotgun",
        laser: "Laser",
        bomb: "Bomb",
        emp: "EMP",
        poison: "Poison",
        basicHint: "Circle. Hits the nearest enemy.",
        shotgunHint: "Triangle. Spreads forward and hits several enemies.",
        laserHint: "Square. Damage grows while it stays on the same enemy.",
        bombHint: "Hexagon. Full damage in the center, half on the spread.",
        empHint: "Star. Splashes around the tower. Stops normal enemies briefly. Bosses only slow down.",
        poisonHint: "Drop. Starts within two tiles and grows with level. Damage ticks, and enemies slow only while poisoned.",
        briefings: lines("""
        Learn the basic winding route and overlap firing ranges at each crossing.
        Long horizontal corridors repeat. Prepare a strong final defense line.
        The exit is centered. Defend every approach evenly.
        A long zigzag route exposes many corners. Stack firepower there.
        Two entrances merge on the central exit. Split your defenses.
        Enemies transfer from the right edge to another left corridor. Watch every lane.
        The route circles the perimeter. Long-range weapons have an advantage.
        Two entrances approach the center. Do not overcommit to one side.
        A long detour surrounds the exit. Keep a rear defense reserve.
        Outer and inner routes connect. Secure the central crossing.
        Wide zigzag lanes favor fast enemies. Prepare interception points.
        Several horizontal corridors are linked by transfers. Predict each exit.
        The route coils around the center. Area damage is effective.
        Symmetric routes attack from both sides. Balance your firepower.
        The outer route narrows toward the center. Reinforce the last line.
        Short corridors repeat. Use explosions against clustered enemies.
        A long diagonal pattern favors fast wild dogs. Prepare early.
        Three horizontal approaches lead to the center. Track each exit.
        The route circles the perimeter twice. Sustained damage is essential.
        Enemies cross the center and turn back. Build a crossfire.
        Entrances alternate from both sides. Watch for robot infiltration.
        Vertical corridors repeat. Spread facilities against tank counterfire.
        A dense horizontal maze makes mine placement critical.
        Multiple lanes enter in a fixed sequence. Anticipate the next corridor.
        A wide route surrounds the central exit. Choose repairs quickly.
        Long crossing routes return. Do not miss the bonus craft.
        Three forces converge at the center. Establish a line for each entrance.
        Outer and inner lanes reconnect. Repair disabled facilities immediately.
        The final wide zigzag drill strengthens every enemy type.
        Final defense: defeat multiple routes and the strongest boss formation.
        """),
        cleared: "All 30 stages cleared.",
        defeated: "Enemies that reached the exit took the last lives.",
        repairing: "Cannot attack while repairing. Attack and upgrades return when repair finishes.",
        maxLevel: "Maximum level is 10.",
        bossHintText: "Boss. Very high health. A leak costs 5 lives.",
        craft: "A bonus craft follows the path quickly. Shoot it down for a large gold reward.",
        stageLineFormat: "STAGE %d",
        recallFormat: "Recall %d",
        waveFormat: "WAVE %d",
        minePlaceFormat: "Mines place at level %1$d. Direct hit %2$d, splash %3$d. Upgrades apply only before placement.",
        durabilityFormat: "Durability %1$d/%2$d. Tap to start repairs. Upgrades are available after repair.",
        upgradingFormat: "Upgrading. The gauge finishes at level %d.",
        mergeFormat: "%1$@ Overlap another level %2$d to start the upgrade. The gauge finishes at level %3$d.",
        upgradeFormat: "%1$@ Tap to upgrade for %2$d gold. Drag to move.",
        recalledFormat: "Gold is reset. Stage %d starts with a new fund.",
        mineMax: "Mine at maximum",
        mineUpgradeFormat: "Upgrade mine %d"
    )

    private static let ja = pack(
        routeDefense: "進路防衛作戦",
        pressAnywhere: "どこでもタップ ...",
        missionBriefing: "作戦説明",
        stageWord: "ステージ",
        allComplete: "全作戦完了",
        createdBy: "制作",
        backToTitle: "タイトルへ",
        settings: "設定",
        soundEffects: "効果音",
        backgroundMusic: "BGM",
        audioNote: "効果音とBGMは別々に設定できます。",
        done: "完了",
        back: "戻る",
        language: "言語",
        lives: "ライフ",
        gold: "ゴールド",
        mines: "地雷",
        mine: "地雷",
        retry: "やり直し",
        recallWord: "回収",
        bossWord: "ボス",
        waveWord: "ウェーブ",
        bossIncoming: "ボス出現",
        basic: "基本",
        shotgun: "ショット",
        laser: "レーザー",
        bomb: "爆弾",
        emp: "EMP",
        poison: "毒",
        basicHint: "円。一番近い敵を攻撃します。",
        shotgunHint: "三角。前方に広がって複数の敵を攻撃します。",
        laserHint: "四角。同じ敵を狙い続けるほどダメージが増えます。",
        bombHint: "六角。中心は全ダメージ、周囲は半分です。",
        empHint: "星。塔の周囲に広がります。通常の敵は止まり、ボスは遅くなります。",
        poisonHint: "滴。最初は2マスで、レベルが上がると広がります。徐々にダメージを与え、効果中だけ遅くなります。",
        briefings: lines("""
        基本の曲がる道です。交差点で射撃範囲を重ねてください。
        長い横通路が繰り返されます。最後の防衛線を厚くしてください。
        出口は中央です。すべての侵入路を均等に守ってください。
        長いジグザグです。角ごとに火力を重ねてください。
        二つの入口が中央の出口で合流します。防衛を分けてください。
        敵は右端から別の左通路へ移ります。すべてのレーンを見てください。
        外周を回る道です。長射程が有利です。
        二つの入口が中央へ近づきます。片方だけに集中しないでください。
        出口を大きく回る迂回路です。後方の備えを残してください。
        外周と内側がつながります。中央の交差点を押さえてください。
        幅の広いジグザグです。速い敵の迎撃地点を作ってください。
        複数の横通路が乗り移りでつながります。次の出口を予測してください。
        中央を巻き込む道です。範囲攻撃が有効です。
        左右対称に攻めてきます。火力のバランスを取ってください。
        外周から中央へ狭まります。最後の防衛線を強化してください。
        短い通路が続きます。密集した敵には爆発を使ってください。
        長い斜めの道は速い野犬が有利です。早めに備えてください。
        三本の横侵入路が中央へ続きます。それぞれの出口を確認してください。
        外周を二周します。持続火力が重要です。
        敵は中央を横切って戻ります。十字砲火を作ってください。
        左右から交互に入ります。ロボットの侵入に注意してください。
        縦通路が繰り返されます。戦車の反撃に備え施設を分散してください。
        密な横迷路です。地雷の位置が重要です。
        複数レーンが決まった順で入ります。次の通路を予測してください。
        広い道が中央の出口を囲みます。修理する施設をすぐ選んでください。
        長い交差路が戻ってきます。ボーナス機を逃さないでください。
        三方向の兵力が中央で合流します。入口ごとに防衛線を作ってください。
        外周と内側が再びつながります。止まった施設はすぐ修理してください。
        広いジグザグの最終訓練です。すべての敵が強くなります。
        最終防衛です。複数ルートと最強のボス編隊を倒してください。
        """),
        cleared: "30ステージをすべてクリアしました。",
        defeated: "出口まで到達した敵が残りのライフを削りました。",
        repairing: "修理中は攻撃できません。完了後に攻撃と強化ができます。",
        maxLevel: "最大は10レベルです。",
        bossHintText: "ボス。体力が非常に高いです。出口まで行くとライフを5失います。",
        craft: "ボーナス機が道に沿って速く通ります。撃墜すると大量のゴールドを得ます。",
        stageLineFormat: "ステージ %d",
        recallFormat: "回収 %d",
        waveFormat: "ウェーブ %d",
        minePlaceFormat: "地雷はレベル%1$dで設置されます。直撃%2$d、周囲%3$d。強化は設置前だけ適用されます。",
        durabilityFormat: "耐久%1$d/%2$d。タップで修理が始まり、修理後に強化できます。",
        upgradingFormat: "強化中。ゲージが完了するとレベル%dになります。",
        mergeFormat: "%1$@ 同じレベル%2$dを重ねると強化が始まり、完了でレベル%3$dになります。",
        upgradeFormat: "%1$@ タップで%2$dゴールドを使い強化。ドラッグで移動します。",
        recalledFormat: "資金を初期化しました。ステージ%dは新しい資金で始まります。",
        mineMax: "地雷は最大",
        mineUpgradeFormat: "地雷強化 %d"
    )

    private static let zh = pack(
        routeDefense: "路线防御作战",
        pressAnywhere: "点击任意位置 ...",
        missionBriefing: "任务简报",
        stageWord: "关卡",
        allComplete: "全部任务完成",
        createdBy: "制作",
        backToTitle: "返回标题",
        settings: "设置",
        soundEffects: "音效",
        backgroundMusic: "背景音乐",
        audioNote: "音效和背景音乐可以分别设置。",
        done: "完成",
        back: "返回",
        language: "语言",
        lives: "生命",
        gold: "金币",
        mines: "地雷",
        mine: "地雷",
        retry: "重试",
        recallWord: "回收",
        bossWord: "首领",
        waveWord: "波次",
        bossIncoming: "首领来袭",
        basic: "基础",
        shotgun: "霰弹",
        laser: "激光",
        bomb: "炸弹",
        emp: "EMP",
        poison: "毒素",
        basicHint: "圆形。攻击最近的敌人。",
        shotgunHint: "三角。向前散射，命中多名敌人。",
        laserHint: "方形。持续锁定同一敌人时伤害会提高。",
        bombHint: "六边形。中心全额伤害，扩散范围一半伤害。",
        empHint: "星形。在塔周围扩散。普通敌人短暂停住，首领只会变慢。",
        poisonHint: "水滴。最初覆盖两格，升级后范围变大。持续受伤，中毒期间才会变慢。",
        briefings: lines("""
        学习基本弯路，在每个交叉点重叠火力。
        长横向走廊会重复。准备一条坚实的最终防线。
        出口在中央。均匀防守每条进路。
        长锯齿路线露出许多拐角。在那里叠加火力。
        两个入口在中央出口汇合。分开布防。
        敌人从右端转入另一条左走廊。看住每条路线。
        路线绕着外圈。远程武器更有利。
        两个入口接近中央。不要只守一边。
        一条长绕路包住出口。留下后方预备。
        外圈和内路相连。守住中央交叉点。
        宽锯齿有利于快速敌人。准备拦截点。
        多条横向走廊由转移连接。预测下一个出口。
        路线绕着中央盘旋。范围伤害很有效。
        左右对称进攻。平衡两边的火力。
        外圈向中央收窄。加强最后防线。
        短走廊连续出现。用爆炸对付聚集的敌人。
        长斜线有利于快速野狗。提前准备。
        三条横向进路通向中央。盯住每个出口。
        路线绕外圈两圈。持续输出很重要。
        敌人穿过中央再折返。建立交叉火力。
        入口从两侧交替出现。当心机器人渗入。
        纵向走廊重复。分散设施，防备坦克反击。
        密集的横向迷宫。地雷位置很关键。
        多条路线按固定顺序进入。预判下一条走廊。
        宽路围住中央出口。尽快选择要修复的设施。
        长交叉路线会折返。不要错过奖励飞船。
        三股兵力在中央汇合。为每个入口建立防线。
        外圈和内路再次相连。立刻修复停火的设施。
        宽锯齿最终训练。所有敌人类型都会变强。
        最终防御：击败多条路线和最强首领编队。
        """),
        cleared: "30个关卡已全部通过。",
        defeated: "到达出口的敌人耗尽了生命。",
        repairing: "修复期间不能攻击。完成后才能攻击和升级。",
        maxLevel: "最高为10级。",
        bossHintText: "首领。生命非常高。漏到出口会失去5点生命。",
        craft: "奖励飞船沿路线快速通过。击落可获得大量金币。",
        stageLineFormat: "关卡 %d",
        recallFormat: "回收 %d",
        waveFormat: "波次 %d",
        minePlaceFormat: "地雷以%1$d级放置。直接命中%2$d，溅射%3$d。升级只对放置前生效。",
        durabilityFormat: "耐久 %1$d/%2$d。点按开始修复，修复后才能升级。",
        upgradingFormat: "升级中。计量完成后变为%d级。",
        mergeFormat: "%1$@ 叠放另一个%2$d级即可开始升级，完成后变为%3$d级。",
        upgradeFormat: "%1$@ 点按花费%2$d金币升级。拖动可以移动。",
        recalledFormat: "资金已重置。关卡%d以新的资金开始。",
        mineMax: "地雷已满级",
        mineUpgradeFormat: "升级地雷 %d"
    )

    private static let fr = pack(
        routeDefense: "DÉFENSE DE LA ROUTE",
        pressAnywhere: "Appuyez n'importe où ...",
        missionBriefing: "BRIEFING",
        stageWord: "NIVEAU",
        allComplete: "TOUTES LES MISSIONS TERMINÉES",
        createdBy: "CRÉÉ PAR",
        backToTitle: "RETOUR AU TITRE",
        settings: "Réglages",
        soundEffects: "Effets sonores",
        backgroundMusic: "Musique",
        audioNote: "Les effets et la musique se règlent séparément.",
        done: "OK",
        back: "RETOUR",
        language: "Langue",
        lives: "Vies",
        gold: "Or",
        mines: "Mines",
        mine: "Mine",
        retry: "Rejouer",
        recallWord: "Rappel",
        bossWord: "BOSS",
        waveWord: "VAGUE",
        bossIncoming: "BOSS EN APPROCHE",
        basic: "Base",
        shotgun: "Fusil",
        laser: "Laser",
        bomb: "Bombe",
        emp: "EMP",
        poison: "Poison",
        basicHint: "Cercle. Touche l'ennemi le plus proche.",
        shotgunHint: "Triangle. Tire vers l'avant et touche plusieurs ennemis.",
        laserHint: "Carré. Les dégâts augmentent s'il reste sur le même ennemi.",
        bombHint: "Hexagone. Dégâts complets au centre, moitié sur la zone.",
        empHint: "Étoile. Zone autour de la tour. Arrête les ennemis normaux. Les boss ralentissent seulement.",
        poisonHint: "Goutte. Deux cases au début, et la zone grandit avec le niveau. Dégâts progressifs, ralentissement pendant l'effet.",
        briefings: lines("""
        Apprenez la route sinueuse et superposez les portées à chaque croisement.
        De longs couloirs horizontaux se répètent. Préparez une dernière ligne solide.
        La sortie est au centre. Défendez chaque approche de façon égale.
        Un long zigzag expose beaucoup de coins. Empilez la puissance de feu.
        Deux entrées se rejoignent à la sortie centrale. Divisez vos défenses.
        Les ennemis passent du bord droit à un autre couloir gauche. Surveillez chaque voie.
        La route fait le tour du périmètre. Les armes longues sont avantagées.
        Deux entrées approchent du centre. Ne misez pas tout sur un seul côté.
        Un long détour entoure la sortie. Gardez une réserve à l'arrière.
        Les routes extérieure et intérieure se rejoignent. Tenez le croisement central.
        De larges zigzags favorisent les ennemis rapides. Préparez des points d'interception.
        Plusieurs couloirs horizontaux sont liés par des transferts. Prévoyez chaque sortie.
        La route s'enroule autour du centre. Les dégâts de zone sont efficaces.
        Des routes symétriques attaquent des deux côtés. Équilibrez votre feu.
        La route extérieure se resserre vers le centre. Renforcez la dernière ligne.
        De courts couloirs se répètent. Utilisez les explosions contre les groupes.
        Une longue diagonale favorise les chiens rapides. Préparez-vous tôt.
        Trois approches horizontales mènent au centre. Suivez chaque sortie.
        La route fait deux tours du périmètre. Les dégâts continus sont essentiels.
        Les ennemis traversent le centre puis reviennent. Créez un tir croisé.
        Les entrées alternent des deux côtés. Attention à l'infiltration des robots.
        Les couloirs verticaux se répètent. Dispersez les installations face aux chars.
        Un labyrinthe horizontal dense rend le placement des mines crucial.
        Plusieurs voies entrent dans un ordre fixe. Anticipez le prochain couloir.
        Une large route entoure la sortie centrale. Choisissez vite les réparations.
        De longues routes croisées reviennent. Ne manquez pas l'appareil bonus.
        Trois forces convergent au centre. Une ligne pour chaque entrée.
        Les voies extérieure et intérieure se reconnectent. Réparez tout de suite les installations arrêtées.
        Le dernier zigzag large renforce chaque type d'ennemi.
        Défense finale : plusieurs routes et la plus forte formation de boss.
        """),
        cleared: "Les 30 niveaux sont terminés.",
        defeated: "Les ennemis arrivés à la sortie ont pris les dernières vies.",
        repairing: "Pas d'attaque pendant la réparation. Attaque et améliorations reviennent à la fin.",
        maxLevel: "Le niveau maximum est 10.",
        bossHintText: "Boss. Vie très élevée. Une fuite coûte 5 vies.",
        craft: "Un appareil bonus suit vite la route. Abattez-le pour beaucoup d'or.",
        stageLineFormat: "NIVEAU %d",
        recallFormat: "Rappel %d",
        waveFormat: "VAGUE %d",
        minePlaceFormat: "Les mines se posent au niveau %1$d. Impact %2$d, zone %3$d. L'amélioration ne vaut que avant la pose.",
        durabilityFormat: "Durabilité %1$d/%2$d. Touchez pour réparer. L'amélioration revient après.",
        upgradingFormat: "Amélioration. La jauge finit au niveau %d.",
        mergeFormat: "%1$@ Superposez un autre niveau %2$d pour commencer. La jauge finit au niveau %3$d.",
        upgradeFormat: "%1$@ Touchez pour améliorer pour %2$d or. Glissez pour déplacer.",
        recalledFormat: "L'or est réinitialisé. Le niveau %d commence avec un nouveau fond.",
        mineMax: "Mine au maximum",
        mineUpgradeFormat: "Améliorer la mine %d"
    )

    private static let pt = pack(
        routeDefense: "DEFESA DA ROTA",
        pressAnywhere: "Toque em qualquer lugar ...",
        missionBriefing: "BRIEFING",
        stageWord: "FASE",
        allComplete: "TODAS AS MISSÕES CONCLUÍDAS",
        createdBy: "CRIADO POR",
        backToTitle: "VOLTAR AO TÍTULO",
        settings: "Ajustes",
        soundEffects: "Efeitos sonoros",
        backgroundMusic: "Música",
        audioNote: "Efeitos e música podem ser ajustados separadamente.",
        done: "OK",
        back: "VOLTAR",
        language: "Idioma",
        lives: "Vidas",
        gold: "Ouro",
        mines: "Minas",
        mine: "Mina",
        retry: "De novo",
        recallWord: "Recolher",
        bossWord: "CHEFE",
        waveWord: "ONDA",
        bossIncoming: "CHEFE A CAMINHO",
        basic: "Básico",
        shotgun: "Escopeta",
        laser: "Laser",
        bomb: "Bomba",
        emp: "EMP",
        poison: "Veneno",
        basicHint: "Círculo. Acerta o inimigo mais próximo.",
        shotgunHint: "Triângulo. Abre para a frente e acerta vários inimigos.",
        laserHint: "Quadrado. O dano cresce enquanto mira o mesmo inimigo.",
        bombHint: "Hexágono. Dano total no centro, metade na área.",
        empHint: "Estrela. Ao redor da torre. Para inimigos normais. Chefes só ficam mais lentos.",
        poisonHint: "Gota. Começa em dois quadrados e cresce com o nível. Dano gradual, lentidão só durante o efeito.",
        briefings: lines("""
        Aprenda a rota curva e sobreponha o alcance em cada cruzamento.
        Corredores horizontais longos se repetem. Prepare uma linha final forte.
        A saída fica no centro. Defenda cada acesso por igual.
        Um zigue-zague longo expõe muitos cantos. Empilhe poder de fogo.
        Duas entradas se encontram na saída central. Divida a defesa.
        Os inimigos passam da borda direita para outro corredor à esquerda. Vigie cada faixa.
        A rota circula o perímetro. Armas de longo alcance levam vantagem.
        Duas entradas se aproximam do centro. Não concentre tudo em um lado.
        Um longo desvio cerca a saída. Deixe uma reserva na retaguarda.
        As rotas externa e interna se ligam. Segure o cruzamento central.
        Zigue-zagues largos favorecem inimigos rápidos. Prepare pontos de interceptação.
        Vários corredores horizontais se ligam por transferências. Preveja cada saída.
        A rota envolve o centro. Dano em área é eficaz.
        Rotas simétricas atacam dos dois lados. Equilibre o fogo.
        A rota externa estreita em direção ao centro. Reforce a última linha.
        Corredores curtos se repetem. Use explosões contra inimigos agrupados.
        Uma diagonal longa favorece cães rápidos. Prepare-se cedo.
        Três acessos horizontais levam ao centro. Acompanhe cada saída.
        A rota circula o perímetro duas vezes. Dano contínuo é essencial.
        Os inimigos cruzam o centro e voltam. Monte um fogo cruzado.
        As entradas alternam dos dois lados. Cuidado com a infiltração dos robôs.
        Corredores verticais se repetem. Espalhe as instalações contra o contra-ataque dos tanques.
        Um labirinto horizontal denso torna a posição das minas crítica.
        Várias faixas entram em ordem fixa. Antecipe o próximo corredor.
        Uma rota larga cerca a saída central. Escolha logo os reparos.
        Rotas cruzadas longas voltam. Não perca a nave bônus.
        Três forças convergem no centro. Uma linha para cada entrada.
        As faixas externa e interna se reconectam. Repare na hora as instalações paradas.
        O zigue-zague largo final fortalece todo tipo de inimigo.
        Defesa final: derrote várias rotas e a formação de chefe mais forte.
        """),
        cleared: "Todas as 30 fases foram concluídas.",
        defeated: "Inimigos que chegaram à saída tiraram as últimas vidas.",
        repairing: "Não ataca durante o reparo. Ataque e melhorias voltam ao terminar.",
        maxLevel: "O nível máximo é 10.",
        bossHintText: "Chefe. Vida muito alta. Uma fuga custa 5 vidas.",
        craft: "Uma nave bônus segue a rota depressa. Derrube-a para muito ouro.",
        stageLineFormat: "FASE %d",
        recallFormat: "Recolher %d",
        waveFormat: "ONDA %d",
        minePlaceFormat: "Minas são colocadas no nível %1$d. Impacto %2$d, área %3$d. A melhoria vale só antes de colocar.",
        durabilityFormat: "Durabilidade %1$d/%2$d. Toque para reparar. A melhoria volta depois.",
        upgradingFormat: "Melhorando. O medidor termina no nível %d.",
        mergeFormat: "%1$@ Sobreponha outro nível %2$d para começar. O medidor termina no nível %3$d.",
        upgradeFormat: "%1$@ Toque para melhorar por %2$d de ouro. Arraste para mover.",
        recalledFormat: "O ouro foi reiniciado. A fase %d começa com um novo fundo.",
        mineMax: "Mina no máximo",
        mineUpgradeFormat: "Melhorar mina %d"
    )

    private static let es = pack(
        routeDefense: "DEFENSA DE LA RUTA",
        pressAnywhere: "Pulse en cualquier lugar ...",
        missionBriefing: "INFORME",
        stageWord: "FASE",
        allComplete: "TODAS LAS MISIONES COMPLETADAS",
        createdBy: "CREADO POR",
        backToTitle: "VOLVER AL TÍTULO",
        settings: "Ajustes",
        soundEffects: "Efectos de sonido",
        backgroundMusic: "Música",
        audioNote: "Los efectos y la música se ajustan por separado.",
        done: "Listo",
        back: "VOLVER",
        language: "Idioma",
        lives: "Vidas",
        gold: "Oro",
        mines: "Minas",
        mine: "Mina",
        retry: "Reintentar",
        recallWord: "Retirar",
        bossWord: "JEFE",
        waveWord: "OLEADA",
        bossIncoming: "JEFE EN CAMINO",
        basic: "Básico",
        shotgun: "Escopeta",
        laser: "Láser",
        bomb: "Bomba",
        emp: "EMP",
        poison: "Veneno",
        basicHint: "Círculo. Golpea al enemigo más cercano.",
        shotgunHint: "Triángulo. Se abre hacia delante y golpea a varios enemigos.",
        laserHint: "Cuadrado. El daño crece mientras sigue al mismo enemigo.",
        bombHint: "Hexágono. Daño completo en el centro, la mitad en el área.",
        empHint: "Estrella. Salpica alrededor de la torre. Detiene a los enemigos normales. Los jefes solo van más lentos.",
        poisonHint: "Gota. Empieza en dos casillas y crece con el nivel. Daño gradual, lentitud solo mientras dura el efecto.",
        briefings: lines("""
        Aprende la ruta curva y superpón los alcances en cada cruce.
        Los pasillos horizontales largos se repiten. Prepara una última línea fuerte.
        La salida está en el centro. Defiende cada acceso por igual.
        Un zigzag largo expone muchas esquinas. Acumula potencia de fuego.
        Dos entradas se unen en la salida central. Divide las defensas.
        Los enemigos pasan del borde derecho a otro pasillo izquierdo. Vigila cada carril.
        La ruta rodea el perímetro. Las armas de largo alcance tienen ventaja.
        Dos entradas se acercan al centro. No lo apuestes todo a un lado.
        Un largo rodeo rodea la salida. Deja una reserva atrás.
        Las rutas exterior e interior se conectan. Asegura el cruce central.
        Los zigzags anchos favorecen a los enemigos rápidos. Prepara puntos de intercepción.
        Varios pasillos horizontales se unen por transferencias. Predice cada salida.
        La ruta se enrolla alrededor del centro. El daño de área es eficaz.
        Rutas simétricas atacan desde ambos lados. Equilibra el fuego.
        La ruta exterior se estrecha hacia el centro. Refuerza la última línea.
        Los pasillos cortos se repiten. Usa explosiones contra los grupos.
        Una diagonal larga favorece a los perros rápidos. Prepárate pronto.
        Tres accesos horizontales llevan al centro. Sigue cada salida.
        La ruta rodea el perímetro dos veces. El daño continuo es esencial.
        Los enemigos cruzan el centro y regresan. Monta un fuego cruzado.
        Las entradas alternan desde ambos lados. Cuidado con la infiltración de robots.
        Los pasillos verticales se repiten. Dispersa las instalaciones frente a los tanques.
        Un laberinto horizontal denso hace crítica la colocación de minas.
        Varios carriles entran en un orden fijo. Anticipa el siguiente pasillo.
        Una ruta ancha rodea la salida central. Elige pronto las reparaciones.
        Las rutas cruzadas largas regresan. No pierdas la nave de bonificación.
        Tres fuerzas convergen en el centro. Una línea para cada entrada.
        Los carriles exterior e interior se reconectan. Repara de inmediato las instalaciones paradas.
        El zigzag ancho final fortalece cada tipo de enemigo.
        Defensa final: derrota varias rutas y la formación de jefe más fuerte.
        """),
        cleared: "Las 30 fases están completas.",
        defeated: "Los enemigos que llegaron a la salida gastaron las últimas vidas.",
        repairing: "No ataca mientras se repara. El ataque y las mejoras vuelven al terminar.",
        maxLevel: "El nivel máximo es 10.",
        bossHintText: "Jefe. Vida muy alta. Una fuga cuesta 5 vidas.",
        craft: "Una nave de bonificación sigue la ruta deprisa. Derríbala para mucho oro.",
        stageLineFormat: "FASE %d",
        recallFormat: "Retirar %d",
        waveFormat: "OLEADA %d",
        minePlaceFormat: "Las minas se colocan en el nivel %1$d. Impacto %2$d, área %3$d. La mejora solo vale antes de colocarlas.",
        durabilityFormat: "Durabilidad %1$d/%2$d. Pulsa para reparar. La mejora vuelve después.",
        upgradingFormat: "Mejorando. El medidor termina en el nivel %d.",
        mergeFormat: "%1$@ Superpón otro nivel %2$d para empezar. El medidor termina en el nivel %3$d.",
        upgradeFormat: "%1$@ Pulsa para mejorar por %2$d de oro. Arrastra para mover.",
        recalledFormat: "El oro se reinicia. La fase %d empieza con un fondo nuevo.",
        mineMax: "Mina al máximo",
        mineUpgradeFormat: "Mejorar mina %d"
    )

    private static let ko = pack(
        routeDefense: "길목 방어 작전",
        pressAnywhere: "아무 곳이나 누르세요 ...",
        missionBriefing: "작전 브리핑",
        stageWord: "스테이지",
        allComplete: "모든 작전 완료",
        createdBy: "만든 사람",
        backToTitle: "처음으로",
        settings: "설정",
        soundEffects: "효과음",
        backgroundMusic: "배경음악",
        audioNote: "효과음과 배경음악은 따로 설정할 수 있습니다.",
        done: "완료",
        back: "돌아가기",
        language: "언어",
        lives: "라이프",
        gold: "골드",
        mines: "지뢰",
        mine: "지뢰",
        retry: "다시 하기",
        recallWord: "회수",
        bossWord: "보스",
        waveWord: "웨이브",
        bossIncoming: "보스 접근",
        basic: "기본",
        shotgun: "샷건",
        laser: "레이저",
        bomb: "폭탄",
        emp: "EMP",
        poison: "독",
        basicHint: "원. 가장 가까운 적을 맞춥니다.",
        shotgunHint: "삼각. 앞으로 퍼져 여러 적을 맞춥니다.",
        laserHint: "사각. 같은 적을 계속 맞출수록 피해가 커집니다.",
        bombHint: "육각. 중심은 전체 피해, 퍼진 곳은 절반입니다.",
        empHint: "별. 탑 주변에 퍼집니다. 일반 적은 잠시 멈추고, 보스는 느려집니다.",
        poisonHint: "물방울. 두 칸에서 시작해 레벨이 오르면 넓어집니다. 피해가 이어지고, 독이 있는 동안만 느려집니다.",
        briefings: lines("""
        기본으로 굽은 길을 익히고, 교차점마다 사거리를 겹치십시오.
        긴 가로 통로가 반복됩니다. 마지막 방어선을 두껍게 준비하십시오.
        출구는 중앙입니다. 모든 접근로를 고르게 지키십시오.
        긴 지그재그라 모서리가 많습니다. 그곳에 화력을 모으십시오.
        두 입구가 중앙 출구에서 만납니다. 방어를 나누십시오.
        적은 오른쪽 끝에서 다른 왼쪽 통로로 넘어갑니다. 모든 길을 살피십시오.
        외곽을 도는 길입니다. 긴 사거리 무기가 유리합니다.
        두 입구가 중앙으로 다가옵니다. 한쪽에만 몰지 마십시오.
        출구를 크게 돌아가는 우회로입니다. 뒤쪽 예비 방어를 남기십시오.
        바깥길과 안쪽 길이 이어집니다. 중앙 교차점을 확보하십시오.
        넓은 지그재그는 빠른 적에게 유리합니다. 요격 지점을 준비하십시오.
        여러 가로 통로가 옮겨 타기로 이어집니다. 다음 출구를 예측하십시오.
        길이 중앙을 감습니다. 범위 공격이 효과적입니다.
        좌우 대칭으로 들어옵니다. 화력 균형을 맞추십시오.
        바깥길이 중앙으로 좁아집니다. 마지막 방어선을 보강하십시오.
        짧은 통로가 반복됩니다. 뭉친 적에게는 폭발을 쓰십시오.
        긴 대각선은 빠른 들개에게 유리합니다. 미리 대비하십시오.
        세 개의 가로 접근로가 중앙으로 이어집니다. 각 출구를 확인하십시오.
        외곽을 두 바퀴 돕니다. 지속 화력이 중요합니다.
        적이 중앙을 가로지른 뒤 되돌아옵니다. 교차 사격을 만드십시오.
        양쪽에서 번갈아 들어옵니다. 로봇의 침투를 살피십시오.
        세로 통로가 반복됩니다. 탱크 반격에 대비해 시설을 분산하십시오.
        촘촘한 가로 미로입니다. 지뢰 위치가 중요합니다.
        여러 길이 정해진 순서로 열립니다. 다음 통로를 예상하십시오.
        넓은 길이 중앙 출구를 감쌉니다. 수리할 시설을 빨리 고르십시오.
        긴 교차 경로가 다시 옵니다. 보너스 우주선을 놓치지 마십시오.
        세 갈래 병력이 중앙에서 만납니다. 입구마다 방어선을 세우십시오.
        바깥길과 안쪽 길이 다시 이어집니다. 멈춘 시설을 바로 수리하십시오.
        마지막 넓은 지그재그에서 모든 적 유형이 강해집니다.
        최종 방어입니다. 여러 경로와 가장 강한 보스 편대를 막으십시오.
        """),
        cleared: "30개 스테이지를 모두 클리어했습니다.",
        defeated: "출구에 도달한 적이 남은 라이프를 가져갔습니다.",
        repairing: "수리 중에는 공격할 수 없습니다. 수리가 끝나면 공격과 강화가 돌아옵니다.",
        maxLevel: "최대 레벨은 10입니다.",
        bossHintText: "보스. 체력이 매우 높습니다. 출구로 새면 라이프를 5 잃습니다.",
        craft: "보너스 우주선이 길을 빠르게 따라옵니다. 맞추면 골드를 많이 받습니다.",
        stageLineFormat: "스테이지 %d",
        recallFormat: "회수 %d",
        waveFormat: "웨이브 %d",
        minePlaceFormat: "지뢰는 %1$d레벨로 설치됩니다. 직격 %2$d, 주변 %3$d. 강화는 설치 전에만 적용됩니다.",
        durabilityFormat: "내구도 %1$d/%2$d. 탭하면 수리가 시작되고, 수리 후에 강화할 수 있습니다.",
        upgradingFormat: "강화 중. 게이지가 끝나면 %d레벨이 됩니다.",
        mergeFormat: "%1$@ 같은 %2$d레벨을 겹치면 강화가 시작되고, 게이지가 끝나면 %3$d레벨이 됩니다.",
        upgradeFormat: "%1$@ 탭하면 %2$d골드로 강화합니다. 드래그하면 이동합니다.",
        recalledFormat: "자금이 초기화되었습니다. 스테이지 %d는 새 자금으로 시작합니다.",
        mineMax: "지뢰가 최대입니다",
        mineUpgradeFormat: "지뢰 강화 %d"
    )

    private static func lines(_ text: String) -> [String] {
        text.split(separator: "\n", omittingEmptySubsequences: true).map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    private static func pack(
        routeDefense: String, pressAnywhere: String, missionBriefing: String, stageWord: String,
        allComplete: String, createdBy: String, backToTitle: String, settings: String,
        soundEffects: String, backgroundMusic: String, audioNote: String, done: String, back: String,
        language: String, lives: String, gold: String, mines: String, mine: String, retry: String,
        recallWord: String, bossWord: String, waveWord: String, bossIncoming: String,
        basic: String, shotgun: String, laser: String, bomb: String, emp: String, poison: String,
        basicHint: String, shotgunHint: String, laserHint: String, bombHint: String, empHint: String, poisonHint: String,
        briefings: [String], cleared: String, defeated: String, repairing: String, maxLevel: String,
        bossHintText: String, craft: String, stageLineFormat: String, recallFormat: String, waveFormat: String,
        minePlaceFormat: String, durabilityFormat: String, upgradingFormat: String, mergeFormat: String,
        upgradeFormat: String, recalledFormat: String, mineMax: String, mineUpgradeFormat: String
    ) -> GameCopy {
        precondition(briefings.count == 30, "briefing count \(briefings.count)")
        return GameCopy(
            routeDefense: routeDefense, pressAnywhere: pressAnywhere, missionBriefing: missionBriefing,
            stageWord: stageWord, allComplete: allComplete, createdBy: createdBy, backToTitle: backToTitle,
            settings: settings, soundEffects: soundEffects, backgroundMusic: backgroundMusic, audioNote: audioNote,
            done: done, back: back, language: language, lives: lives, gold: gold, mines: mines, mine: mine,
            retry: retry, recallWord: recallWord, bossWord: bossWord, waveWord: waveWord, bossIncoming: bossIncoming,
            basic: basic, shotgun: shotgun, laser: laser, bomb: bomb, emp: emp, poison: poison,
            basicHint: basicHint, shotgunHint: shotgunHint, laserHint: laserHint, bombHint: bombHint,
            empHint: empHint, poisonHint: poisonHint, briefings: briefings, cleared: cleared, defeated: defeated,
            repairing: repairing, maxLevel: maxLevel, bossHintText: bossHintText, craft: craft,
            stageLineFormat: stageLineFormat, recallFormat: recallFormat, waveFormat: waveFormat,
            minePlaceFormat: minePlaceFormat, durabilityFormat: durabilityFormat, upgradingFormat: upgradingFormat,
            mergeFormat: mergeFormat, upgradeFormat: upgradeFormat, recalledFormat: recalledFormat,
            mineMax: mineMax, mineUpgradeFormat: mineUpgradeFormat
        )
    }
}

enum BriefingTips {
    static func label(_ language: AppLanguage) -> String {
        switch language {
        case .ja: "ヒント"
        case .zh: "提示"
        case .fr: "CONSEIL"
        case .pt: "DICA"
        case .es: "CONSEJO"
        case .ko: "팁"
        case .en: "TIP"
        }
    }

    static func lines(_ language: AppLanguage) -> [String] {
        switch language {
        case .en: en
        case .ja: ja
        case .zh: zh
        case .fr: fr
        case .pt: pt
        case .es: es
        case .ko: ko
        }
    }

    private static let en = [
        "Drag a tower onto an empty tile to move it.",
        "Drag a level 7 tower onto another level 7 of the same weapon. The gauge runs, then it becomes level 8. 8+8 makes 9, and 9+9 makes 10.",
        "Tap the mine count to upgrade mines. When the gauge finishes, mines already on the path get stronger too.",
        "Tap a tower at full health to upgrade it with gold, up to level 7.",
        "Place towers off the path. Place mines on the path.",
        "When the field is empty, the next wave starts on its own after 10 seconds.",
        "Tap a damaged tower to repair it. It cannot shoot while repairing.",
        "Recall returns 80% of the gold spent on the selected tower or mine.",
    ]
    private static let ja = [
        "タワーを空いているマスへドラッグすると移動できます。",
        "同じ武器のレベル7を、もう一つのレベル7の上へドラッグします。ゲージが終わるとレベル8になります。8+8は9、9+9は10です。",
        "地雷の数をタップすると強化できます。ゲージが終わると、道に置いた地雷も強くなります。",
        "体力が満タンのタワーをタップすると、ゴールドでレベル7まで強化できます。",
        "タワーは道の外、地雷は道の上に置きます。",
        "フィールドが空になると、10秒後に次のウェーブが自動で始まります。",
        "傷ついたタワーをタップすると修理します。修理中は攻撃できません。",
        "回収すると、選んだタワーや地雷に使ったゴールドの80%が戻ります。",
    ]
    private static let zh = [
        "把塔拖到空格上即可移动。",
        "把相同武器的7级塔拖到另一座7级塔上。进度条结束后变为8级。8+8为9，9+9为10。",
        "点地雷数量可以升级地雷。进度条结束后，路上已放的地雷也会变强。",
        "点满血的塔，可用金币升级到7级。",
        "塔放在道路外，地雷放在道路上。",
        "场上没有敌人时，10秒后下一波会自动开始。",
        "点受损的塔可以修理。修理期间无法攻击。",
        "回收会返还所选塔或地雷已花费金币的80%。",
    ]
    private static let fr = [
        "Faites glisser une tourelle sur une case vide pour la déplacer.",
        "Faites glisser une tourelle de niveau 7 sur une autre de niveau 7 et de même arme. La jauge se remplit, puis elle passe au niveau 8. 8+8 donne 9, et 9+9 donne 10.",
        "Touchez le nombre de mines pour les renforcer. À la fin de la jauge, les mines déjà posées deviennent aussi plus fortes.",
        "Touchez une tourelle à pleine vie pour l'améliorer avec de l'or, jusqu'au niveau 7.",
        "Placez les tourelles hors du chemin, et les mines sur le chemin.",
        "Quand le terrain est vide, la vague suivante commence seule après 10 secondes.",
        "Touchez une tourelle endommagée pour la réparer. Elle ne tire pas pendant la réparation.",
        "Le rappel rend 80 % de l'or dépensé pour la tourelle ou la mine choisie.",
    ]
    private static let pt = [
        "Arraste uma torre para um espaço vazio para movê-la.",
        "Arraste uma torre de nível 7 para outra de nível 7 da mesma arma. O medidor enche e ela vira nível 8. 8+8 vira 9, e 9+9 vira 10.",
        "Toque na quantidade de minas para melhorá-las. Quando o medidor acaba, as minas já colocadas também ficam mais fortes.",
        "Toque numa torre com vida cheia para melhorá-la com ouro, até o nível 7.",
        "Coloque torres fora do caminho e minas sobre o caminho.",
        "Quando o campo fica vazio, a próxima onda começa sozinha após 10 segundos.",
        "Toque numa torre danificada para repará-la. Ela não atira durante o reparo.",
        "Recolher devolve 80% do ouro gasto na torre ou mina escolhida.",
    ]
    private static let es = [
        "Arrastra una torre a una casilla vacía para moverla.",
        "Arrastra una torre de nivel 7 sobre otra de nivel 7 de la misma arma. El medidor se llena y pasa a nivel 8. 8+8 llega a 9, y 9+9 llega a 10.",
        "Toca la cantidad de minas para mejorarlas. Al terminar el medidor, las minas ya colocadas también se vuelven más fuertes.",
        "Toca una torre con la vida llena para mejorarla con oro, hasta el nivel 7.",
        "Coloca las torres fuera del camino y las minas sobre el camino.",
        "Cuando el campo queda vacío, la siguiente oleada empieza sola a los 10 segundos.",
        "Toca una torre dañada para repararla. No dispara mientras se repara.",
        "Retirar devuelve el 80% del oro gastado en la torre o mina elegida.",
    ]
    private static let ko = [
        "포탑을 빈 칸으로 드래그하면 옮길 수 있습니다.",
        "같은 무기 7레벨을 7레벨 위로 드래그하면 강화가 시작되고, 게이지가 끝나면 8레벨이 됩니다. 8+8은 9, 9+9는 10입니다.",
        "지뢰 개수를 누르면 지뢰를 강화합니다. 게이지가 끝나면 길에 깔린 지뢰도 함께 강해집니다.",
        "체력이 가득 찬 포탑을 탭하면 골드로 7레벨까지 강화합니다.",
        "포탑은 길 밖에, 지뢰는 길 위에 설치합니다.",
        "필드가 비면 10초 뒤에 다음 웨이브가 스스로 시작됩니다.",
        "손상된 포탑을 탭하면 수리합니다. 수리 중에는 공격하지 못합니다.",
        "회수는 선택한 포탑이나 지뢰에 쓴 골드의 80%를 돌려줍니다.",
    ]
}
