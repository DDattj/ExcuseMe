//
//  MainView.swift
//  ExcuseMe
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
    private let levels: [Level] = (1...20).map { Level(id: $0, title: "출근 \($0)일차") }
    @State private var isAppLoading: Bool = true
    
    var body: some View {
        
        TabView {
            NavigationStack {
                LevelSelectView(levels: levels.reversed())
                // 여기서 Level 값을 받아 실제로 화면을 이동.
                // 이 부분이 없으면 링크를 눌러도 아무 반응이 없음
                    .navigationDestination(for: Level.self) { level in
                        contentView(for: level)
                    }
                    .navigationTitle("Excuse Me!")
            }
            //메인에 띄울 네비게이션 창 커스텀
            .tabItem { Label("메인", systemImage: "calendar")}
            SettingView().tabItem { Label("집", systemImage: "house")}
            ShopView().tabItem { Label("상점", systemImage: "c.circle")}
            SettingView()
                .tabItem { Label("설정", systemImage: "gear") }
        }
        if isAppLoading {
                    // "타입"을 .appLaunch로 지정!
                    LoadingView(type: .appLaunch) // 메시지는 기본값 사용("오늘도 칼퇴를 위해...")
                        .transition(.opacity.animation(.easeInOut))
                        .zIndex(10) // 탭뷰보다 위에
                        .task {
                            // 1.5초 동안 로딩 보여주기
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            withAnimation {
                                isAppLoading = false
                            }
                        }
                }
            }
    
    
    // 뷰 생성 함수
    func contentView(for level: Level) -> some View {
        // level.id를 사용하여 해당 레벨의 게임을 생성
        let vm = GameViewModel(rows: 6, cols: 6, goalExitSide: .right, level: level.id)
        return ContentView(vm: vm)
    }
}


struct LevelSelectView: View {
    let levels: [Level]
    
    //플레이한 라운드 색상 및 잠금 해제 확인용 (자동 갱신)
    @AppStorage("clearedLevel") private var clearedLevel: Int = 0
    
    //플레이 되지 않은 라운드 클릭 시 알림창을 띄우기 위한 변수들
    @State private var showLockedAlert = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                //버튼 간격
                LazyVStack(spacing: 50) {
                    
                    Color.clear.frame(height: 1).id("topSpacer")
                    
                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                        
                        // 지그재그: 특정 인덱스에서는 가운데 고정
                        let minOffset: CGFloat = 40
                        let maxOffset: CGFloat = 100
                        let seed = level.id &* 1_000_003 &+ index
                        
                        // 방향: 짝수 인덱스는 왼쪽(-), 홀수 인덱스는 오른쪽(+)
                        let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                        
                        // 크기: 각 아이템마다 서로 다르게, min...max 범위에서 뽑기
                        let magnitude = pseudoRandomInRange(seed: seed, min: minOffset, max: maxOffset)
                        
                        // 가운데로 고정할 조건:
                        // - 매 15개마다: index % 15 == 0  (index는 0부터 시작하므로 0,15,30,...)
                        // - 마지막 아이템도 포함하려면: || index == levels.count - 1
                        let shouldCenter = (index % 15 == 0) || (index == levels.count - 1)
                        let xOffset: CGFloat = shouldCenter ? 0 : direction * magnitude
                        
                        // 레벨이 잠겨있는지 확인, 내 레벨(clearedLevel)이 0이면 1탄만 열려야 함 (0 + 1 >= 1)
                        // 1탄을 깼으면(clearedLevel=1) 2탄까지 열림 (1 + 1 >= 2)
                        let isLocked = level.id > (clearedLevel + 1)
                        
                        // 버튼 디자인 (NavigationLink 대신 Button 사용), NavigationLink는 누르면 무조건 이동해버려서, 조건부 이동이 어렵다
                        Group {
                            if isLocked {
                                // 1. 잠긴 경우: 알림창을 띄우는 '버튼'만 표시
                                Button {
                                    showLockedAlert = true
                                } label: {
                                    LevelCircleView(level: level, isLocked: true, clearedLevel: clearedLevel)}
                            } else {
                                // 2. 열린 경우: 바로 이동하는 '네비게이션 링크'만 표시 (버튼 없음)
                                NavigationLink(value: level) {
                                    LevelCircleView(level: level, isLocked: false, clearedLevel: clearedLevel)
                                }
                            }
                        }
                        .id(level.id)
                        .frame(maxWidth: .infinity)
                        .offset(x: xOffset)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Color.clear.frame(height: 100).id("bottomSpacer")
                }
                .padding(.vertical)
            }
            .onAppear {
                // 화면이 켜지면 내가 깬 레벨로 스크롤 이동
                DispatchQueue.main.async {
                    withAnimation {
                        if clearedLevel == 0 {
                            proxy.scrollTo("bottomSpacer", anchor: .bottom)
                        } else {
                            proxy.scrollTo(clearedLevel, anchor: UnitPoint(x: 0.5, y: 0.8))
                        }
                    }
                }
            }
            
            // 잠긴 레벨 눌렀을 때 뜨는 알림창
            .alert("잠시만요!", isPresented: $showLockedAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("이전 단계를 먼저 클리어해주세요.\n차근차근 올라가 볼까요?")
            }
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
    
    // 레벨 버튼 디자인을 별도 뷰로 분리
    struct LevelCircleView: View {
        let level: Level
        let isLocked: Bool
        let clearedLevel: Int
        
        var body: some View {
            Circle()
                // 잠김(회색) / 깸(파랑) / 도전가능(보라)
                .fill(isLocked ? Color.gray.opacity(0.5) : (level.id <= clearedLevel ? Color.blue.opacity(0.3) : Color.purple))
                .frame(width: 80, height: 80)
                .overlay(
                    VStack {
                        if isLocked {
                            Image(systemName: "lock.fill")
                            Text("출근\n준비중")
                                .font(.callout)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(level.title) // "출근 n일차"
                                .font(.headline)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                )
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
