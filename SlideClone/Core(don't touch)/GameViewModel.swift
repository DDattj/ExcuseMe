//
//  GameViewModel.swift
//  SlideClone
//
//  Created by 이시안 on 12/5/25.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    
    let objectWillChange = ObservableObjectPublisher()
    
    private let core: GameCore
    private var initialCars: [Car] = []
    
    //현재 레벨을 기억하는 변수 추가
    private let currentLevel: Int
    
    @Published var cars: [Car] = []
    @Published var hasWon: Bool = false
    @Published var moveCount: Int = 0
    @Published var obstacleMoveCount: Int = 0
    
    //초기화할 때 'level'을 입력받도록 수정
    init(rows: Int, cols: Int, goalExitSide: GameCore.ExitSide, level: Int) {
        let core = GameCore(rows: rows, cols: cols, goalExitSide: goalExitSide)
        
        // 들어온 레벨을 기억해둠
        self.currentLevel = level
        
        //코어에게 레벨 정보를 전달하며 보드 생성 요청
        let initialCars = core.generatePlayableBoard(level: level)
        let initialHasWon = core.isGoalState(initialCars)
        
        self.core = core
        self.cars = initialCars
        self.initialCars = initialCars // 초기상태를 저장한다.
        self.hasWon = initialHasWon
        self.moveCount = 0
        self.obstacleMoveCount = 0
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    func tryAgain() {
        // 저장해둔 현재 레벨(currentLevel)로 다시 생성
        cars = core.generatePlayableBoard(level: currentLevel)
        initialCars = cars // 초기 상태 업데이트
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
    
    // 뷰에서 이동 가능한지 물어볼 때 사용하는 함수
    func calculateAllowedSteps(index: Int, axis: Axis, startRow: Int, startCol: Int, desiredDelta: Int) -> Int {
        // GameCore에게 대신 물어보고 결과를 반환
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
