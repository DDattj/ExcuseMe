//
//  ItemDatabase.swift
//  ExcuseMe
//
//  Created by [User] on ...
//

import Foundation

// 아이템 데이터 보관소 (가게 창고)
struct ItemDatabase {
    
    // 전체 아이템 리스트 (나중에는 서버에서 받아올 수도 있음)
    static let allItems: [ShopItem] = [
        // [자동차 스킨]
        ShopItem(id: "skin_red", type: .carSkin, name: "기본 레드", description: "기본 지급 차량", price: 0, resourceName: "red"),
        ShopItem(id: "skin_blue", type: .carSkin, name: "시원한 블루", description: "칼퇴의 꿈을 담은 색", price: 100, resourceName: "blue"),
        ShopItem(id: "skin_mint", type: .carSkin, name: "상쾌한 민트", description: "눈이 편안해지는 색", price: 200, resourceName: "mint"),
        ShopItem(id: "skin_gold", type: .carSkin, name: "부자의 골드", description: "돈 많은 백수의 상징", price: 500, resourceName: "yellow"),
        
        // [가구 - 예시]
        ShopItem(id: "fur_bed_01", type: .furniture, name: "딱딱한 침대", description: "잠만 잘 수 있음", price: 50, resourceName: "bed_basic")
    ]
    
    // ID로 아이템 정보를 찾아주는 편리한 함수
    static func findItem(id: String) -> ShopItem? {
        return allItems.first { $0.id == id }
    }
    
    // 종류별로 아이템을 필터링해주는 함수 (상점에서 탭 나눌 때 유용)
    static func getItems(type: ItemType) -> [ShopItem] {
        return allItems.filter { $0.type == type }
    }
}
