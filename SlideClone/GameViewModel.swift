//상태 추가+카운트 로직 변경:
//점수, 시간 제한, 힌트 수 같은 새로운 상태 → @Published로 추가.


import SwiftUI
import Combine


final class GameViewModel: ObservableObject {
    
    // MARK: - 컨텐츠뷰
    let objectWillChange = ObservableObjectPublisher()
    
    private let core: GameCore
    
    @Published var cars: [Car] = []
    @Published var hasWon: Bool = false
    @Published var moveCount: Int = 0
    @Published var obstacleMoveCount: Int = 0
    
    init(rows: Int, cols: Int, goalExitSide: GameCore.ExitSide) {
        // Initialize core first
        let core = GameCore(rows: rows, cols: cols, goalExitSide: goalExitSide)
        // Prepare initial values without touching self
        let initialCars = core.generatePlayableBoard()
        let initialHasWon = core.isGoalState(initialCars)
        
        // Assign stored properties
        self.core = core
        self.cars = initialCars
        self.hasWon = initialHasWon
        self.moveCount = 0
        self.obstacleMoveCount = 0
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    func tryAgain() {
        cars = core.generatePlayableBoard()
        hasWon = false
        moveCount = 0
        obstacleMoveCount = 0
        hasWon = core.isGoalState(cars)
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

