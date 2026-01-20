//
//  GameViewModel.swift
//  ExcuseMe
//
//  Created by 이시안 on 12/5/25.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    
    private let core: GameCore
    //게임 기록 저장용
    private var currentSeed: Int = 0
    
    //게임 처음 상태 저장
    private var initialCars: [Car] = []
    // 현재 레벨을 기억
    @Published var currentLevel: Int
    @Published var cars: [Car] = []
    @Published var hasWon: Bool = false
    @Published var moveCount: Int = 0
    @Published var obstacleMoveCount: Int = 0
    @Published var isLoading: Bool = true
    
    init(rows: Int, cols: Int, goalExitSide: GameCore.ExitSide, level: Int) {
        let core = GameCore(rows: rows, cols: cols, goalExitSide: goalExitSide)
        self.core = core
        self.currentLevel = level
        self.cars = []
        self.initialCars = []
        self.isLoading = true // 로딩 중 표시
    }
    
    var goalExitSide: GameCore.ExitSide { core.goalExitSide }
    
    @MainActor
    func loadLevel() async {
        self.isLoading = true
        
        // 너무 빨리 깜빡이는 것 방지 (0.1초 대기)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // 백그라운드 스레드에서 무거운 계산 수행
        let (newCars, seed) = await Task.detached { [weak self] () -> ([Car], Int) in
            guard let self = self else { return ([], 0) }
            
            // 시드 확인 로직
            let savedSeed = UserDefaults.standard.integer(forKey: "Seed_Level_\(await self.currentLevel)")
            let currentSeed = (savedSeed != 0) ? savedSeed : Int.random(in: 1...999999)
            
            // 여기서 맵 생성 (무거운 작업)
            let generatedCars = await self.core.generatePlayableBoard(level: self.currentLevel, seed: currentSeed)
            
            return (generatedCars, currentSeed)
        }.value
        
        // UI 업데이트 (메인 스레드)
        self.currentSeed = seed
        self.cars = newCars
        self.initialCars = newCars
        self.hasWon = self.core.isGoalState(newCars)
        self.moveCount = 0
        self.obstacleMoveCount = 0
        
        self.isLoading = false // 로딩 끝
    }
    
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
    
    // 다음 레벨로 넘어가는 함수
    func moveToNextLevel() {
        
        //코인 보상을 지금
        GameData.shared.addCoins(50)
        print("\(GameData.shared.coins)원")
        
        //방금 깬 레벨의 시드를 영구 저장, 다음에 오면 이 맵 보여줌
        UserDefaults.standard.set(currentSeed, forKey: "Seed_Level_\(currentLevel)")
        GameData.shared.saveClearLevel(currentLevel)
        
        currentLevel += 1
        
        Task {
            await loadLevel()
        }
    }
}

