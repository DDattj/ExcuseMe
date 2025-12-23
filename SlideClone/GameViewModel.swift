//상태 추가+카운트 로직 변경:
//점수, 시간 제한, 힌트 수 같은 새로운 상태 → @Published로 추가.


import SwiftUI
import Combine


final class GameViewModel: ObservableObject {
    
    // MARK: - 컨텐츠뷰
    let objectWillChange = ObservableObjectPublisher()
    
    private let core: GameCore
    private let difficulty: Int
    
    @Published var cars: [Car] = []
    @Published var hasWon: Bool = false
    @Published var moveCount: Int = 0
    @Published var obstacleMoveCount: Int = 0
    
    init(rows: Int, cols: Int, goalExitSide: GameCore.ExitSide, difficulty: Int = 1) {
        // Initialize core first
        let core = GameCore(rows: rows, cols: cols, goalExitSide: goalExitSide)
        // Clamp difficulty to at least 1
        let clampedDifficulty = max(1, difficulty)
        // Prepare initial values
        let initialCars = core.generatePlayableBoard(difficulty: clampedDifficulty)
        let initialHasWon = core.isGoalState(initialCars)

        // Assign stored properties
        self.core = core
        self.difficulty = clampedDifficulty
        self.cars = initialCars
        self.hasWon = initialHasWon
        self.moveCount = 0
        self.obstacleMoveCount = 0
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    func tryAgain() {
        cars = core.generatePlayableBoard(difficulty: difficulty)
        hasWon = core.isGoalState(cars)
        moveCount = 0
        obstacleMoveCount = 0
    }
    
    func applyMove(from startRow: Int, startCol: Int, to newRow: Int, newCol: Int, isGoal: Bool) {
        if startRow != newRow || startCol != newCol {
            moveCount += 1
            if !isGoal {
                obstacleMoveCount += 1
            }
        }
        hasWon = core.isGoalState(cars)
    }
    
    }

