//
//  GameData.swift
//  SlideClone
//
//  Created by 이시안 on 1/9/26.

import Foundation

// 심부름꾼 (데이터 관리자)
class GameData {
    // 누구나 부를 수 있게 'shared'라는 명찰을 달아줍니다.
    static let shared = GameData()
    
    // 키워드(열쇠) 이름 실수하지 않게 변수로 저장
    private let clearKey = "clearedLevel"
    
    // 1. 저장하기 (심부름꾼아, 이거 적어놔!)
    func saveClearLevel(_ level: Int) {
        // 기존에 저장된 기록보다 높을 때만 저장 (3탄 깼는데 1탄 깼다고 덮어쓰면 안 되니까)
        let currentBest = loadClearLevel()
        if level > currentBest {
            UserDefaults.standard.set(level, forKey: clearKey)
        }
    }
    
    // 2. 불러오기 (심부름꾼아, 몇 탄까지 깼지?)
    func loadClearLevel() -> Int {
        return UserDefaults.standard.integer(forKey: clearKey)
    }
}
