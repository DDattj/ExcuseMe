//Created by 이시안 on 12/5/25.

//GameCore와 UI를 연결하며, 게임 승리 여부(hasWon)와 이동 횟수(moveCount) 등을 관리


import SwiftUI
import Combine


final class GameViewModel: ObservableObject {
    
    // MARK: - 컨텐츠뷰
    let objectWillChange = ObservableObjectPublisher()
    
    private let core: GameCore
    private var initialCars: [Car] = []
    
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
        self.initialCars = initialCars //초기상태를 저장한다.
        self.hasWon = initialHasWon
        self.moveCount = 0
        self.obstacleMoveCount = 0
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    func tryAgain() {
        cars = initialCars
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
    
    //뷰에서 이동 가능한지 물어볼 때 사용하는 함수, 이거 하는 이유는 뷰에서 쓸데없는 계산 안하게 하려고
        func calculateAllowedSteps(index: Int, axis: Axis, startRow: Int, startCol: Int, desiredDelta: Int) -> Int {
            //GameCore에게 대신 물어보고 결과를 반환
            return core.allowedDeltaInState(
                for: cars,
                index: index,
                axis: axis,
                startRow: startRow,
                startCol: startCol,
                desiredDelta: desiredDelta
            )
        }
    
    }

