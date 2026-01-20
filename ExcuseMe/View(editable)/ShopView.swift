//
//  ShopView.swift
//  ExcuseMe
//
//  Created by 이시안 on 1/20/26.
//
import SwiftUI

struct ShopView: View {
    // 실시간 데이터 감지
    @State private var myCoins = GameData.shared.coins
    @State private var equipped = GameData.shared.equippedSkin
    @State private var myInventory = GameData.shared.inventory
    
    // 알림창 관련 변수
    @State private var showPurchaseAlert = false
    @State private var selectedItem: ShopItem? = nil
    
    // 카테고리 선택 (스킨 vs 가구)
    @State private var selectedCategory: ItemType = .carSkin
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ZStack{
                // 배경색 (약간 회색빛으로 깔끔하게)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    //상단 지갑영역
                    walletHeader
                    
                    //카테고리 탭 (스킨 / 가구)
                    categoryPicker
                        .padding()
                    
                    //아이템 리스트
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            // 선택된 카테고리에 맞는 아이템만 필터링해서 보여줌
                            let filteredItems = ItemDatabase.getItems(type: selectedCategory)
                            
                            ForEach(filteredItems) { item in
                                ItemCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("상점")
            .navigationBarTitleDisplayMode(.inline)
            
            // 4. 구매 확인 알림창
            .alert("구매 확인", isPresented: $showPurchaseAlert, presenting: selectedItem) { item in
                Button("구매하기 (-\(item.price))") {
                    if GameData.shared.buyItem(item: item) {
                        refreshData() // 성공 시 화면 갱신
                        // 성공 햅틱 피드백
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
                Button("취소", role: .cancel) {}
            } message: { item in
                let count = GameData.shared.getItemCount(itemId: item.id)
                Text("\(item.name)을(를) 구매하시겠습니까?\n현재 보유 수량: \(count)개")
            }
        }
        .onAppear { refreshData() }
    }
    
    // MARK: - UI Components
    
    // 지갑 디자인
    var walletHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("나의 보유 코인")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "wonsign.circle.fill")
                        .foregroundStyle(.yellow)
                    Text("\(myCoins)")
                        .font(.title2)
                        .bold()
                        .contentTransition(.numericText(value: Double(myCoins))) // 숫자 바뀔 때 애니메이션
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .overlay(Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2)), alignment: .bottom)
    }
    
    // 카테고리 선택 탭
    var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            Text("자동차 스킨").tag(ItemType.carSkin)
            Text("인테리어 가구").tag(ItemType.furniture)
        }
        .pickerStyle(.segmented)
    }
    
    // 데이터 새로고침
    func refreshData() {
        myCoins = GameData.shared.coins
        myInventory = GameData.shared.inventory
        equipped = GameData.shared.equippedSkin
    }
    
    // MARK: - Item Card View
    @ViewBuilder
    func ItemCard(item: ShopItem) -> some View {
        let count = myInventory[item.id] ?? 0
        let isEquipped = (equipped == item.id)
        
        VStack(alignment: .leading, spacing: 10) {
            // 1. 아이템 이미지 영역
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 100)
                
                // 실제 색상 보여주기 (문자열 -> 컬러 변환)
                if item.type == .carSkin {
                    Image(systemName: "car.side.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .foregroundStyle(stringToColor(item.resourceName))
                        .shadow(radius: 2)
                } else {
                    // 가구일 경우 (아이콘 예시)
                    Image(systemName: "sofa.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.brown)
                }
            }
            
            // 2. 텍스트 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // 가격 표시
                HStack(spacing: 2) {
                    Image(systemName: "wonsign.circle")
                        .font(.caption)
                    Text("\(item.price)")
                        .font(.subheadline)
                        .bold()
                }
                .foregroundStyle(item.price > myCoins ? .red : .primary) // 돈 부족하면 빨간색
            }
            
            // 3. 버튼 영역
            if item.type == .carSkin && count > 0 {
                // [스킨 & 보유중] -> 장착 버튼
                Button {
                    if !isEquipped {
                        GameData.shared.equippedSkin = item.id
                        refreshData()
                        // 햅틱
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                } label: {
                    Text(isEquipped ? "장착 중" : "장착하기")
                        .font(.caption)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isEquipped ? Color.gray.opacity(0.3) : Color.blue)
                        .foregroundStyle(isEquipped ? .gray : .white)
                        .cornerRadius(8)
                }
                .disabled(isEquipped)
                
            } else {
                // [미보유] 또는 [가구] -> 구매 버튼 (가구는 여러 개 살 수 있으므로 항상 구매 버튼)
                Button {
                    selectedItem = item
                    showPurchaseAlert = true
                } label: {
                    Text("구매하기")
                        .font(.caption)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(myCoins >= item.price ? Color.orange : Color.gray.opacity(0.3))
                        .foregroundStyle(myCoins >= item.price ? .white : .gray)
                        .cornerRadius(8)
                }
                .disabled(myCoins < item.price)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        // 보유 뱃지 (우측 상단)
        .overlay(alignment: .topTrailing) {
            if count > 0 {
                Text("x\(count)")
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }
    
    // 색상 변환 헬퍼 (나중에는 이미지 이름으로 교체 가능)
    func stringToColor(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "blue": return .blue
        case "mint": return .mint
        case "yellow": return .yellow
        case "black": return .black
        default: return .gray
        }
    }
}

#Preview {
    ShopView()
}
