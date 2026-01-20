//
//  ShopItem.swift
//  ExcuseMe
//
//  Created by [User] on ...
//

import Foundation

// 아이템의 종류 (자동차 스킨인지, 집 꾸미기 가구인지)
enum ItemType: String, Codable {
    case carSkin    // 자동차 스킨
    case furniture  // 가구 (나중에 추가)
    case wallpaper  // 벽지 (나중에 추가)
}

struct ShopItem: Identifiable, Codable {
    let id: String          // 고유 ID (예: "skin_001")
    let type: ItemType      // 아이템 종류
    let name: String        // 이름
    let description: String // 설명 (예: "야근할 때 타는 차")
    let price: Int          // 가격
    let resourceName: String // 이미지나 색상 코드 이름 (예: "red" 또는 "img_car_sport")
}
