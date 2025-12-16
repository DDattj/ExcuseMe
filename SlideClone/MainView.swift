//
//  MainView.swift
//  SlideClone
//
//  Created by 이시안 on 12/11/25.


//메인 화면으로 쓰일 UI 파일
struct Level: Identifiable, Hashable {
    let id: Int
    let title: String
}

import SwiftUI

struct MainView: View {
    // 1부터 30까지 오름차순
    private let levels: [Level] = (1...30).map { Level(id: $0, title: "출근 \($0)일차") }

    var body: some View {
        TabView {
            NavigationStack {
                LevelSelectView(levels: levels.reversed())
                    .navigationTitle("Excuse Me!")
            }
            .tabItem { Label("메인", systemImage: "calendar")}
            SettingsView().tabItem { Label("집", systemImage: "house")}
            SettingsView().tabItem { Label("상점", systemImage: "c.circle")}
            SettingsView()
                .tabItem { Label("설정", systemImage: "gear") }
        }
    }
}

struct LevelSelectView: View {
    let levels: [Level] // [1, 2, 3, ... 30]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                //버튼 간격
                LazyVStack(spacing: 50) {
                    ForEach(levels) { level in
                        NavigationLink(value: level) {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(level.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                )
                        }
                        .id(level.id) // 스크롤 타겟
                    }
                    .padding(.horizontal)
                    
                    //하단 여백을 '컨텐츠'로 추가 (탭 바와 간격 확보)
                    Color.clear
                        .frame(height: 100)
                        .id("bottomSpacer")
                }
                .padding(.vertical)
            }
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo("bottomSpacer", anchor: .bottom)
                    }
                }
            }
        }
        .navigationDestination(for: Level.self) { level in
            ContentView()
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gear")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("설정 준비 중")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("설정")
        }
    }
}


#Preview {
    MainView()
}

