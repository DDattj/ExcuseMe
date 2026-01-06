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
            //내 캐릭터 색 설정
            return .red
        } else {
            return horizontal ? .blue : .green
        }
    }
}

struct ContentView: View {
    let rows = 6 //세로 칸
    let cols = 6 //가로 칸
    let spacing: CGFloat = 3 //칸 사이 간격
    
    @StateObject private var vm = GameViewModel(rows: 6, cols: 6, goalExitSide: .right)
    
    @State private var activeIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var startRow: Int = 0
    @State private var startCol: Int = 0
    @State private var dragAxis: Axis? = nil
    
    @State private var isDragging: Bool = false
    @State private var shakePhase: CGFloat = 0
    @State private var lastAllowedDelta: Int = 0
    
    // MARK: - 충돌 계산 (UI 쪽에서 사용하는 그리드)
    
    private func buildOccupancyGrid(excluding index: Int?) -> [[Bool]] {
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)
        for (i, car) in vm.cars.enumerated() {
            if let index = index, i == index { continue }
            if car.horizontal {
                for c in car.col..<(car.col + car.length) { grid[car.row][c] = true }
            } else {
                for r in car.row..<(car.row + car.length) { grid[r][car.col] = true }
            }
        }
        return grid
    }
    
    private func allowedDelta(
        for car: Car,
        index: Int,
        axis: Axis,
        startRow: Int,
        startCol: Int,
        desiredDelta: Int
    ) -> Int {
        let grid = buildOccupancyGrid(excluding: index)
        
        switch axis {
        case .horizontal:
            if desiredDelta > 0 {
                // 오른쪽
                var maxSteps = 0
                let startEdge = startCol + car.length - 1
                var nextCol = startEdge + 1
                while maxSteps < desiredDelta && nextCol < cols {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                // 왼쪽
                var maxSteps = 0
                var nextCol = startCol - 1
                while maxSteps < -desiredDelta && nextCol >= 0 {
                    if grid[car.row][nextCol] { break }
                    maxSteps += 1
                    nextCol -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
            
        case .vertical:
            if desiredDelta > 0 {
                // 아래
                var maxSteps = 0
                let startEdge = startRow + car.length - 1
                var nextRow = startEdge + 1
                while maxSteps < desiredDelta && nextRow < rows {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow += 1
                }
                return maxSteps
            } else if desiredDelta < 0 {
                // 위
                var maxSteps = 0
                var nextRow = startRow - 1
                while maxSteps < -desiredDelta && nextRow >= 0 {
                    if grid[nextRow][car.col] { break }
                    maxSteps += 1
                    nextRow -= 1
                }
                return -maxSteps
            } else {
                return 0
            }
        }
    }
    
    // MARK: - View
    
    var body: some View {
        VStack(spacing: 30) {
            //다시시작 버튼
            HStack {
                Button("Try Again!") {
                    vm.tryAgain()
                    activeIndex = nil
                    dragAxis = nil
                    dragOffset = .zero
                    startRow = vm.cars.first?.row ?? 0
                    startCol = vm.cars.first?.col ?? 0
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            
            GeometryReader { geo in
                
                let rawSide = min(geo.size.width, geo.size.height) - 8
                let side = max(rawSide, 0)
                let cell = side > 0 ? (side - spacing * CGFloat(cols - 1)) / CGFloat(cols) : 0
                
                let contentWidth  = cell * CGFloat(cols) + spacing * CGFloat(cols - 1)
                let contentHeight = cell * CGFloat(rows) + spacing * CGFloat(rows - 1)
                
                let gridOriginX = (side - contentWidth)  / 2
                let gridOriginY = (side - contentHeight) / 2
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: side, height: side)
                    
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
                    
                    // Exit marker
                    Group {
                        switch vm.goalExitSide {
                        case .right:
                            let cell = (side - spacing * CGFloat(cols - 1)) / CGFloat(cols)
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
                            
                        case .left, .top, .bottom:
                            EmptyView()
                        }
                    }
                    
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
        .alert("휴! 탈출이다", isPresented: $vm.hasWon) {
            Button("이동") {
                vm.tryAgain()
                activeIndex = nil
                dragAxis = nil
                dragOffset = .zero
                startRow = vm.cars.first?.row ?? 0
                startCol = vm.cars.first?.col ?? 0
            }
            Button("종료하기", role: .cancel) {}
        } message: {
            Text("잠시만요 횟수: \(vm.obstacleMoveCount)")
        }
        .onAppear {
            if vm.cars.isEmpty {
                vm.tryAgain()
                startRow = vm.cars.first?.row ?? 0
                startCol = vm.cars.first?.col ?? 0
            }
        }
    }
    
    // MARK: - Car View
    func carView(for car: Car, index: Int, cell: CGFloat, origin: CGSize) -> some View {
        
        let width  = car.horizontal
        ? cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)
        : cell
        let height = car.horizontal
        ? cell
        : cell * CGFloat(car.length) + spacing * CGFloat(car.length - 1)
        
        // 기본 위치 (Grid Position)
        let offsetX = origin.width  + CGFloat(car.col) * (cell + spacing)
        let offsetY = origin.height + CGFloat(car.row) * (cell + spacing)
        
        // 드래그에 의한 이동
        let currentDragX = (activeIndex == index) ? dragOffset.width : 0
        let currentDragY = (activeIndex == index) ? dragOffset.height : 0
        
        // 흔들림 효과 (sin 함수로 파동 만들기)
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
        // 위치 적용: 기본위치 + 드래그변위 + 흔들림
            .offset(x: offsetX + currentDragX + shakeX,
                    y: offsetY + currentDragY + shakeY)
            .zIndex(activeIndex == index ? 100 : 1)
        // 애니메이션: 드래그 값 변화에 따라 부드럽게
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 1. 초기화
                        if activeIndex == nil {
                            activeIndex = index
                            startRow = vm.cars[index].row
                            startCol = vm.cars[index].col
                            dragAxis = vm.cars[index].horizontal ? .horizontal : .vertical
                            isDragging = true
                        }
                        guard activeIndex == index, let axis = dragAxis else { return }
                        
                        let step = cell + spacing
                        
                        // 2. 드래그 거리 -> 칸 수 변환
                        let translation = axis == .horizontal ? value.translation.width : value.translation.height
                        let desiredSteps = Int(round(translation / step))
                        
                        // 3. 갈 수 있는 거리 계산 (변수명 allowedSteps로 통일)
                        let allowedSteps = allowedDelta(
                            for: vm.cars[index],
                            index: index,
                            axis: axis,
                            startRow: startRow,
                            startCol: startCol,
                            desiredDelta: desiredSteps
                        )
                        
                        // 4. 드래그 오프셋 적용
                        if axis == .horizontal {
                            dragOffset = CGSize(width: CGFloat(allowedSteps) * step, height: 0)
                        } else {
                            dragOffset = CGSize(width: 0, height: CGFloat(allowedSteps) * step)
                        }
                        
                        // 5. 충돌 감지 (원하는 거리 > 허용된 거리)
                        let isBlocked = abs(desiredSteps) > abs(allowedSteps)
                        
                        // 6. 흔들림 효과 발동
                        if isBlocked && shakePhase == 0 {
                            // 폰 진동
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.impactOccurred()
                            
                            // 화면 진동
                            withAnimation(.linear(duration: 1)) {
                                shakePhase = 20
                            }
                            
                            // 진동 끝난 후 초기화
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    shakePhase = 0
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        guard activeIndex == index, let axis = dragAxis else { return }
                        
                        let step = cell + spacing
                        
                        // 최종 이동 확정
                        let movedSteps = Int(round((axis == .horizontal ? dragOffset.width : dragOffset.height) / step))
                        
                        if movedSteps != 0 {
                            // 모델 업데이트
                            if axis == .horizontal {
                                vm.cars[index].col = startCol + movedSteps
                            } else {
                                vm.cars[index].row = startRow + movedSteps
                            }
                            
                            // 게임 로직 반영
                            vm.applyMove(from: startRow, startCol: startCol,
                                         to: vm.cars[index].row, newCol: vm.cars[index].col,
                                         isGoal: car.isGoal)
                        }
                        
                        // 상태 초기화
                        resetDragState()
                    }
            )
    }
    // 초기화 헬퍼 함수
    func resetDragState() {
        activeIndex = nil
        dragOffset = .zero
        dragAxis = nil
        isDragging = false
        shakePhase = 0
    }
}
#Preview {
    ContentView()
}
