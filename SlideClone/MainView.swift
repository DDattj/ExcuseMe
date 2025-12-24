//
//  MainView.swift
//  SlideClone
//
//  Created by 이시안 on 12/11/25.


import SwiftUI

//메인 화면으로 쓰일 UI 파일
struct Level: Identifiable, Hashable {
    let id: Int
    let title: String
}


struct MainView: View {
    // 1부터 n라운드까지 오름차순
    private let levels: [Level] = (1...10).map { Level(id: $0, title: "출근 \($0)일차") }

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
                    
                    Color.clear
                        .frame(height: -5)
                        .id("topSpacer")
                    
                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                        
                        // 지그재그: 특정 인덱스에서는 가운데 고정
                        let minOffset: CGFloat = 40
                        let maxOffset: CGFloat = 100

                        // index/level.id 기반 seed로 재현 가능한 난수 생성
                        let seed = level.id &* 1_000_003 &+ index

                        // 방향: 짝수 인덱스는 왼쪽(-), 홀수 인덱스는 오른쪽(+)
                        let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1

                        // 크기: 각 아이템마다 서로 다르게, min...max 범위에서 뽑기
                        let magnitude = pseudoRandomInRange(seed: seed, min: minOffset, max: maxOffset)

                        // 가운데로 고정할 조건:
                        // - 매 15개마다: index % 15 == 0  (index는 0부터 시작하므로 0,15,30,...)
                        // - 마지막 아이템도 포함하려면: || index == levels.count - 1
                        let shouldCenter = (index % 15 == 0) || (index == levels.count - 1)

                        // 최종 오프셋
                        let xOffset: CGFloat = shouldCenter ? 0 : direction * magnitude

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
                        .id(level.id)
                        .frame(maxWidth: .infinity)
                        .offset(x: xOffset)
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
                        proxy.scrollTo("topSpacer", anchor: UnitPoint.top) // 타입 명시로 에러 방지
                    }
                }
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
    
    //지그재그 모양으로 올라갈 수 있도록 만들 예정
    func pseudoRandomInRange(seed: Int, min: CGFloat, max: CGFloat) -> CGFloat {
        // 간단한 LCG 기반 해시 → 0...1
        var x = UInt64(bitPattern: Int64(seed))
        x = x &* 6364136223846793005 &+ 1
        let unit = Double((x >> 11) & 0x3FF) / 1023.0 // 0...1
        let value = Double(min) + (Double(max - min) * unit)
        return CGFloat(value)
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

