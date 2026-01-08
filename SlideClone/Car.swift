//
//  Car.swift
//  SlideClone
//
//  Created by 이시안 on 1/8/26.
//

//차에 대한 정보는 크게 바뀌지 않을것
//그렇다고 생성할때마다 매번 코어 찾아가서 긴 파일을 분석하는 일은 하지말라고 만드는 폴더

import Foundation

struct Car: Hashable {
    var row: Int        // 세로 위치 (몇 번째 줄)
    var col: Int        // 가로 위치 (몇 번째 칸)
    var length: Int     // 자동차 길이 (2칸 or 3칸)
    var horizontal: Bool // 가로 방향인지? (true: 가로, false: 세로)
    var isGoal: Bool    // 내가 조종하는 주인공 차인지?
}
