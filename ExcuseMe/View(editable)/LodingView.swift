//
//  LoadingView.swift
//  ExcuseMe
//
//  Created by 이시안 on 1/15/26.
//

import SwiftUI

//로딩의 종류를 정의, 만들고 싶은 로딩 있으면 케이스 더 만들어가면 됨
enum LoadingType {
    case mapGeneration  // 맵 생성 (무거운 작업)
    case navigation     // 화면 이동 (가벼운 작업)
    case appLaunch      // 앱 실행 (환영)
    
    // 각 상황별 아이콘
    var iconName: String {
        switch self {
        case .mapGeneration: return "map.fill"
        case .navigation: return "arrow.turn.up.right"
        case .appLaunch: return "gamecontroller.fill"
        }
    }
    
    // 각 상황별 색상
    var color: Color {
        switch self {
        case .mapGeneration: return .pink.opacity(0.6)
        case .navigation: return .blue
        case .appLaunch: return .orange
        }
    }
}

//MARK: -로딩을 구체적으로 어떻게 만들것인가

//1. 영역 만들기
struct LoadingView: View {
    let type: LoadingType
    var message: String? = nil // 메시지는 선택사항 (안 넣으면 기본 문구)
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            //배경색
            Color.white.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 타입별로 다른 애니메이션과 아이콘
                iconView
                
                // 텍스트 영역
                VStack(spacing: 8) {
                    Text(titleText)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(message ?? defaultMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
//2. 본격적으로 모양 만들기
    @ViewBuilder
    var iconView: some View {
        switch type {
        case .mapGeneration:
            // 1. 맵 생성: 톱니바퀴나 지도가 뱅글뱅글 도는 느낌
            Image("SampleSmile") //이미지 이름이나 아이콘 이름 넣기
                .resizable()
                .scaledToFit()
                .font(.system(size: 50))
                .foregroundStyle(type.color)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                /*.overlay(
                    Image(systemName: "hammer.fill")
                        .font(.title)
                        .offset(x: 20, y: -20)
                        .rotationEffect(.degrees(isAnimating ? -20 : 20))
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isAnimating)
                )*/
            
        case .navigation:
            // 2. 이동: 화살표가 슝슝 움직이는 느낌
            HStack(spacing: 10) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(type.color)
                        .frame(width: 15, height: 15)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
        case .appLaunch:
            // 3. 앱 실행: 로고가 두근두근 커지는 느낌
            Image(systemName: type.iconName)
                .font(.system(size: 60))
                .foregroundStyle(type.color)
                .scaleEffect(isAnimating ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        }
    }
    
//MARK: - 멘트 설정
    
    // 타입별 기본 제목
    var titleText: String {
        switch type {
        case .mapGeneration: return "공사 중!"
        case .navigation: return "이동 중"
        case .appLaunch: return "Excuse Me"
        }
    }
    
    // 타입별 기본 설명
    var defaultMessage: String {
        switch type {
        case .mapGeneration: return "복잡한 퇴근길을 만들고 있어요."
        case .navigation: return "잠시만 기다려주세요."
        case .appLaunch: return "오늘도 칼퇴를 위해 준비 중..."
        }
    }
}

//MARK: - 이곳에서 테스트 가능
#Preview {
    VStack {
        LoadingView(type: .mapGeneration)
            .frame(height: 200)
        LoadingView(type: .navigation)
            .frame(height: 200)
        LoadingView(type: .appLaunch)
            .frame(height: 200)
    }
}
