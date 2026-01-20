//
//  GameData.swift
//  ExcuseMe
//
//  Created by 이시안 on 1/9/26.

import Foundation

// 데이터 관리자
class GameData {
    
    //MARK: - 게임이름
    
    // 누구나 부를 수 있게 'shared'붙임
    static let shared = GameData()
    
    // 이름 실수하지 않게 변수로 저장
    private let clearKey = "clearedLevel"
    private let coinKey = "userCoins"
    private let inventoryKey = "userInventory"
    private let equipSkinKey = "equippedSkin"
    
    //MARK: - 게임 저장
    
    // 1. 게임 저장하기
    func saveClearLevel(_ level: Int) {
        // 기존에 저장된 기록보다 높을 때만 저장 = 3탄 깼는데 1탄 깼다고 덮어쓰면 안 되니까
        let currentBest = loadClearLevel()
        if level > currentBest {
            UserDefaults.standard.set(level, forKey: clearKey)
        }
    }
    // 2. 게임 불러오기
    func loadClearLevel() -> Int {
        return UserDefaults.standard.integer(forKey: clearKey)
    }
    
    //MARK: - 코인 관리
    
    // 코인 불러오기
    var coins: Int {
        get { UserDefaults.standard.integer(forKey: coinKey) }
        set { UserDefaults.standard.set(newValue, forKey: coinKey) }
    }
    
    // 코인 획득 함수
    func addCoins(_ amount: Int) {
        coins += amount
    }
    func useCoins(_ amount: Int) -> Bool {
        if coins >= amount {
            coins -= amount
            return true
        }
        return false
    }
    
    //MARK: - 샵 아이템 관련
    
    // [아이템ID : 개수] 형태로 저장
    var inventory: [String: Int] {
        get {
            return UserDefaults.standard.dictionary(forKey: inventoryKey) as? [String: Int] ?? ["skin_red": 1]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: inventoryKey)
        }
    }
    
    // 현재 장착 중인 스킨
        var equippedSkin: String {
            get { UserDefaults.standard.string(forKey: equipSkinKey) ?? "skin_red" }
            set { UserDefaults.standard.set(newValue, forKey: equipSkinKey) }
        }
    
    // 특정 아이템을 몇 개 가지고 있는지 확인하는 함수
    func getItemCount(itemId: String) -> Int {
        return inventory[itemId] ?? 0
    }
    
    // 아이템 구매 함수 (개수 증가 로직)
    func buyItem(item: ShopItem) -> Bool {
        if coins >= item.price {
            coins -= item.price
            
            var current = inventory
            // 기존 개수에 +1 (없으면 0에서 시작)
            current[item.id, default: 0] += 1
            inventory = current // 저장
            
            return true
        }
        return false
    }
}

