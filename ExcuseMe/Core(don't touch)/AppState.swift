//
//  AppState.swift
//  ExcuseMe
//
//  Created by 이시안 on 1/21/26.
//

import SwiftUI
import Combine

// 탭의 종류를 정의
enum TabType: Int {
    case main = 0
    case home = 1
    case shop = 2
    case settings = 3
}

class AppState: ObservableObject {
    @Published var selectedTab: TabType = .main
    
    // 게임 중인지 확인하는 변수
    @Published var isGamePlaying: Bool = false
    // 알림창 띄울지 여부
    @Published var showExitAlert: Bool = false
    // 이동하려고 했던 탭 저장용
    var targetTab: TabType? = nil
}
