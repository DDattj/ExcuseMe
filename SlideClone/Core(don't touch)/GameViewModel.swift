//
//  GameViewModel.swift
//  SlideClone
//
//  Created by 이시안 on 12/5/25.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    
    private let core: GameCore
    
    //게임 처음 상태 저장
    private var initialCars: [Car] = []
    // 현재 레벨을 기억
    private let currentLevel: Int
    
    @Published var cars: [Car] = []
    @Published var hasWon: Bool = false
    @Published var moveCount: Int = 0
    @Published var obstacleMoveCount: Int = 0
    
    init(rows: Int, cols: Int, goalExitSide: GameCore.ExitSide, level: Int) {
        let core = GameCore(rows: rows, cols: cols, goalExitSide: goalExitSide)
        self.currentLevel = level
        
        // 1. 코어에게 레벨에 맞는 맵을 만들어달라고 요청
        let createdCars = core.generatePlayableBoard(level: level)
        let initialHasWon = core.isGoalState(createdCars)
        
        self.core = core
        
        // 2. 만든 맵을 '화면용(cars)'과 '보관용(initialCars)' 두 군데에 담기
        self.cars = createdCars
        self.initialCars = createdCars
        
        self.hasWon = initialHasWon
        self.moveCount = 0
        self.obstacleMoveCount = 0
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    //다시 시작 기능
    func tryAgain() {
        // 처음에 보관해둔 원본(initialCars)을 꺼내서 덮어씌우기
        cars = initialCars
        
        // 점수와 승리 상태도 0으로 되돌림
        hasWon = false
        moveCount = 0
        obstacleMoveCount = 0
        
        // 승리 여부 재확인
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
    
    // 뷰에서 이동 가능한지 물어볼 때 사용하는 함수
    func calculateAllowedSteps(index: Int, axis: Axis, startRow: Int, startCol: Int, desiredDelta: Int) -> Int {
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
