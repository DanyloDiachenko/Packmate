import SwiftUI

struct SectionOption: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let color: Color

    static let defaults: [SectionOption] = [
        SectionOption(id: "documents", name: "Documents & Money", iconName: "doc.fill", color: Color(hex: "F59E0B")),
        SectionOption(id: "clothes", name: "Clothes & Footwear", iconName: "tshirt.fill", color: Color(hex: "10B981")),
        SectionOption(id: "tech", name: "Electronics & Tech", iconName: "laptopcomputer", color: Color(hex: "38BDF8")),
        SectionOption(id: "toiletries", name: "Toiletries & Health", iconName: "cross.case.fill", color: Color(hex: "C084FC")),
        SectionOption(id: "misc", name: "Misc & Gear", iconName: "bag.fill", color: Color(hex: "F43F5E"))
    ]
}

struct AddItemDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddItemViewModel
    @FocusState private var isTitleFocused: Bool

    init(
        initialSection: String = "Clothes & Footwear",
        onAddItem: ((CreateTripItemRequest) -> String?)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: AddItemViewModel(
            initialSection: initialSection,
            onAddItem: onAddItem,
            onClose: onClose
        ))
    }

    var body: some View {
        ZStack {
            AppTheme.darkBackground
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    isTitleFocused = false
                }

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color(hex: "3A3F4D"))
                    .frame(width: 36, height: 4.5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                drawerHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        titleInputField

                        sectionSelectorField

                        HStack(alignment: .top, spacing: 14) {
                            quantityStepperField
                            priorityTagField
                        }

                        submitButton
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isTitleFocused = false
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.configureInitialSection(viewModel.selectedSection)
        }
        .onDisappear {
            isTitleFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private var drawerHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.electricBlue.opacity(0.18))
                        .frame(width: 34, height: 34)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.skyCyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Item")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Add to packing checklist")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            Spacer()

            Button(action: {
                isTitleFocused = false
                if let onClose = viewModel.onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }

    private var titleInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ITEM NAME")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.5)

            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.errorMessage != nil ? Color(hex: "EF4444") : AppTheme.skyCyan)
                    .frame(width: 18)

                TextField(
                    "",
                    text: $viewModel.itemTitle,
                    prompt: Text("e.g. Passport, Power bank, Rain jacket")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                )
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .focused($isTitleFocused)
                .autocapitalization(.words)
                .disableAutocorrection(false)
                .submitLabel(.done)
                .onSubmit {
                    if viewModel.isFormValid {
                        isTitleFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        viewModel.handleSubmit(dismiss: { dismiss() })
                    }
                }
                .onChange(of: viewModel.itemTitle) { _ in
                    if viewModel.errorMessage != nil {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.errorMessage = nil
                        }
                    }
                }

                if !viewModel.itemTitle.isEmpty {
                    Button(action: {
                        viewModel.itemTitle = ""
                        if viewModel.errorMessage != nil {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.errorMessage = nil
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                viewModel.errorMessage != nil
                                    ? Color(hex: "EF4444").opacity(0.8)
                                    : (isTitleFocused ? AppTheme.electricBlue.opacity(0.6) : AppTheme.inputBorder.opacity(0.6)),
                                lineWidth: 1
                            )
                    )
            )

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "EF4444"))

                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "EF4444"))
                        .lineLimit(2)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "EF4444").opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color(hex: "EF4444").opacity(0.25), lineWidth: 1)
                        )
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var sectionSelectorField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORY / SECTION")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SectionOption.defaults) { option in
                        let isSelected = viewModel.selectedSection.lowercased() == option.name.lowercased()

                        Button(action: {
                            isTitleFocused = false
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                viewModel.selectedSection = option.name
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: option.iconName)
                                    .font(.system(size: 12, weight: .bold))

                                Text(option.name)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? option.color : Color(hex: "181C26"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(isSelected ? Color.clear : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(
                                        color: isSelected ? option.color.opacity(0.4) : Color.clear,
                                        radius: 6,
                                        x: 0,
                                        y: 2
                                    )
                            )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var quantityStepperField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUANTITY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.5)

            HStack(spacing: 10) {
                Button(action: {
                    isTitleFocused = false
                    viewModel.decrementQuantity()
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(viewModel.quantity > 1 ? .white : AppTheme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(viewModel.quantity > 1 ? 0.08 : 0.03))
                        .clipShape(Circle())
                }
                .disabled(viewModel.quantity <= 1)

                Text("\(viewModel.quantity)x")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(minWidth: 32)

                Button(action: {
                    isTitleFocused = false
                    viewModel.incrementQuantity()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.inputBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.inputBorder.opacity(0.6), lineWidth: 1)
                    )
            )
        }
    }

    private var priorityTagField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRIORITY TAG")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.textSecondary)
                .tracking(0.5)

            Menu {
                ForEach(ItemTag.allCases, id: \.self) { tag in
                    Button(action: {
                        isTitleFocused = false
                        viewModel.selectedTag = tag
                    }) {
                        Label(tag.rawValue, systemImage: viewModel.tagIcon(for: tag))
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.tagIcon(for: viewModel.selectedTag))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(viewModel.selectedTag.tagColor)

                    Text(viewModel.selectedTag.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.selectedTag.tagColor)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.inputBorder.opacity(0.6), lineWidth: 1)
                        )
                )
            }
            .simultaneousGesture(TapGesture().onEnded {
                isTitleFocused = false
            })
        }
    }

    private var submitButton: some View {
        Button(action: {
            isTitleFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            viewModel.handleSubmit(dismiss: { dismiss() })
        }) {
            HStack(spacing: 7) {
                Image(systemName: viewModel.isFormValid ? "plus" : "circle.slash")
                    .font(.system(size: 14, weight: .bold))

                Text("Add to Packing List")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(viewModel.isFormValid ? .white : Color(hex: "94A3B8"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                if viewModel.isFormValid {
                    LinearGradient(
                        colors: [Color(hex: "0284C7"), Color(hex: "2563EB")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(25)
                } else {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color(hex: "252A36"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                }
            }
            .shadow(
                color: viewModel.isFormValid ? AppTheme.electricBlue.opacity(0.6) : Color.clear,
                radius: 14,
                x: 0,
                y: 5
            )
        }
        .disabled(!viewModel.isFormValid)
    }
}

struct AddItemDrawer_Previews: PreviewProvider {
    static var previews: some View {
        AddItemDrawer()
    }
}
