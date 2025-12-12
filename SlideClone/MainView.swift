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
                LazyVStack(spacing: 50) {
                    ForEach(levels) { level in
                        NavigationLink(value: level) {
                            Color.clear.frame(height: 300)
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
                }
                .padding(.vertical)
            }
            .onAppear {
                // 맨 아래 아이템(마지막 레벨)로 스크롤, 하단 정렬
                if let last = levels.last {
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
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
