//
//  ContentView.swift
//  SlideClone
//
//  Created by 이시안 on 9/25/25.

//게임 화면으로 쓰일 UI 파일
// 색, 폰트, 레이아웃, 애니메이션: 전부 ContentView에서 수정.

import SwiftUI

// UI 전용 색 설정
extension Car {
    var color: Color {
        if isGoal {
            return .red // 내 캐릭터 색
        } else {
            return horizontal ? .blue : .green // 장애물 색
            //여기 나중에 랜덤 컬러 불러오게 하려면 어떻게 하면 되는지 물어보기
        }
    }
}

struct ContentView: View {
    // 뷰에서 사용할 그리드 설정
    // 실제 로직은 ViewModel/Core에 있는 값을 따름
    // 여기있는 값은 '크기' 계산용입니다.
    let rows = 6
    let cols = 6
    let spacing: CGFloat = 3
    
    // 뷰모델 연결
    @StateObject private var vm: GameViewModel
    
    // 드래그 및 애니메이션 상태 관리 변수들
    @State private var activeIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var startRow: Int = 0
    @State private var startCol: Int = 0
    @State private var dragAxis: Axis? = nil
    @State private var isDragging: Bool = false
    @State private var shakePhase: CGFloat = 0
    
    // MainView에서 vm을 전달받기 위해 init 추가
    init(vm: GameViewModel = GameViewModel(rows: 6, cols: 6, goalExitSide: .right)) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 30) {
            // 상단: 다시시작 버튼
            HStack {
                Button("Try Again!") {
                    vm.tryAgain()
                    resetDragState()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            
            // 메인 게임 보드 영역
            GeometryReader { geo in
                // 화면 크기에 맞춰서 칸 크기(cell) 계산
                let rawSide = min(geo.size.width, geo.size.height) - 8
                let side = max(rawSide, 0)
                let cell = side > 0 ? (side - spacing * CGFloat(cols - 1)) / CGFloat(cols) : 0
                
                // 그리드 전체 크기와 원점 계산
                let contentWidth  = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
                let contentHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)
                let gridOriginX = (side - contentWidth)  / 2
                let gridOriginY = (side - contentHeight) / 2
                
                ZStack(alignment: .topLeading) {
                    // 1. 배경 판 (연한 보라색)
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: side, height: side)
                    
                    // 2. 그리드 칸 (더 연한 보라색)
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { _ in
                            HStack(spacing: spacing) {
                                ForEach(0..<cols, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.purple.opacity(0.18))
                                        .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                    .frame(width: side, height: side)
                    
                    // 3. 출구 표시 (Exit Marker)
                    drawExitMarker(side: side, cell: cell, spacing: spacing)
                    
                    // 4. 자동차들 배치
                    ForEach(vm.cars.indices, id: \.self) { i in
                        carView(
                            for: vm.cars[i],
                            index: i,
                            cell: cell,
                            origin: CGSize(width: gridOriginX, height: gridOriginY)
                        )
                    }
                }
                .frame(width: side, height: side)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .padding()
        // 승리 시 알림창
        .alert("휴! 탈출이다", isPresented: $vm.hasWon) {
            Button("다음 레벨로") {
                vm.tryAgain()
                resetDragState()
            }
            Button("종료하기", role: .cancel) {}
        } message: {
            Text("움직인 횟수: \(vm.moveCount)\n장애물 이동: \(vm.obstacleMoveCount)")
        }
        .onAppear {
            // 화면이 켜지면 게임이 준비되었는지 확인
            if vm.cars.isEmpty {
                vm.tryAgain()
            }
        }
    }
    
    // MARK: - Helper Views
    
    // 출구 그리기
    @ViewBuilder
    func drawExitMarker(side: CGFloat, cell: CGFloat, spacing: CGFloat) -> some View {
        switch vm.goalExitSide {
        case .right:
            let contentWidth  = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
            let contentHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)
            let gridOriginX = (side - contentWidth)  / 2
            let gridOriginY = (side - contentHeight) / 2
            let y = gridOriginY + CGFloat(rows / 2) * (cell + spacing)
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: spacing * 2, height: cell)
                .overlay(
                    Capsule()
                        .fill(Color.orange)
                        .frame(width: spacing * 2, height: cell * 0.6)
                )
                .position(x: gridOriginX + contentWidth + spacing, y: y + cell/2)
        default:
            EmptyView()
        }
    }
    
    // 자동차 그리기 및 드래그 로직
    func carView(for car: Car, index: Int, cell: CGFloat, origin: CGSize) -> some View {
        
        let width  = car.horizontal
            ? cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)
            : cell
        let height = car.horizontal
            ? cell
            : cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)
        
        // 차의 현재 위치 계산
        let offsetX = origin.width  + CGFloat(car.col) * (cell + spacing)
        let offsetY = origin.height + CGFloat(car.row) * (cell + spacing)
        
        // 드래그 중일 때 위치 변화
        let currentDragX = (activeIndex == index) ? dragOffset.width : 0
        let currentDragY = (activeIndex == index) ? dragOffset.height : 0
        
        // 흔들림 효과 (벽에 부딪혔을 때)
        let shakeX = (activeIndex == index && car.horizontal) ? sin(shakePhase) * 5 : 0
        let shakeY = (activeIndex == index && !car.horizontal) ? sin(shakePhase) * 5 : 0
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(car.color)
            .frame(width: width, height: height)
            .shadow(color: .black.opacity((activeIndex == index && isDragging) ? 0.1 : 0.3),
                    radius: (activeIndex == index && isDragging) ? 5 : 2,
                    x: 0, y: (activeIndex == index && isDragging) ? 5 : 2)
            .overlay {
                if car.isGoal { Text("★").font(.largeTitle).foregroundColor(.white) }
            }
            .offset(x: offsetX + currentDragX + shakeX,
                    y: offsetY + currentDragY + shakeY)
            .zIndex(activeIndex == index ? 100 : 1) // 드래그 중인 차를 제일 위로
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 1. 드래그 시작 초기화
                        if activeIndex == nil {
                            activeIndex = index
                            startRow = vm.cars[index].row
                            startCol = vm.cars[index].col
                            dragAxis = vm.cars[index].horizontal ? .horizontal : .vertical
                            isDragging = true
                        }
                        guard activeIndex == index, let axis = dragAxis else { return }
                        
                        let step = cell + spacing
                        
                        // 2. 드래그한 거리 -> 몇 칸 움직이려 하는지 계산
                        let translation = axis == .horizontal ? value.translation.width : value.translation.height
                        let desiredSteps = Int(round(translation / step))
                        
                        // 3. [중요] 뷰모델에게 "이만큼 가도 돼?"라고 물어봅니다. (직접 계산 X)
                        let allowedSteps = vm.calculateAllowedSteps(
                            index: index,
                            axis: axis,
                            startRow: startRow,
                            startCol: startCol,
                            desiredDelta: desiredSteps
                        )
                        
                        // 4. 실제 드래그 위치 업데이트
                        if axis == .horizontal {
                            dragOffset = CGSize(width: CGFloat(allowedSteps) * step, height: 0)
                        } else {
                            dragOffset = CGSize(width: 0, height: CGFloat(allowedSteps) * step)
                        }
                        
                        // 5. 충돌 감지 (원하는 것보다 덜 움직였다면 벽에 막힌 것)
                        let isBlocked = abs(desiredSteps) > abs(allowedSteps)
                        
                        // 6. 막혔다면 흔들림 효과
                        if isBlocked && shakePhase == 0 {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            withAnimation(.linear(duration: 1)) { shakePhase = 20 }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) { shakePhase = 0 }
                            }
                        }
                    }
                    .onEnded { _ in
                        guard activeIndex == index, let axis = dragAxis else { return }
                        
                        let step = cell + spacing
                        let movedSteps = Int(round((axis == .horizontal ? dragOffset.width : dragOffset.height) / step))
                        
                        if movedSteps != 0 {
                            // 이동 확정: 모델 업데이트 요청
                            let newRow = axis == .horizontal ? startRow : startRow + movedSteps
                            let newCol = axis == .horizontal ? startCol + movedSteps : startCol
                            
                            // 로컬 데이터도 업데이트 (UI 즉각 반응용)
                            if axis == .horizontal { vm.cars[index].col = newCol }
                            else { vm.cars[index].row = newRow }
                            
                            vm.applyMove(from: startRow, startCol: startCol,
                                         to: newRow, newCol: newCol,
                                         isGoal: car.isGoal)
                        }
                        resetDragState()
                    }
            )
    }
    
    // 상태 초기화 함수
    func resetDragState() {
        activeIndex = nil
        dragOffset = .zero
        dragAxis = nil
        isDragging = false
        shakePhase = 0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
