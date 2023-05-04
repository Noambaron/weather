import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    let store: StoreOf<Search>
    @ObservedObject var viewStore: ViewStore<ViewState, Search.Action>

    struct ViewState: Equatable {
        var state: Search.State
        
        var textInput: String {
            state.textInput
        }
        
        var searchResults: [Place] {
            state.searchResults
        }
        
        var errorMessage: String? {
            state.error
        }
        
        var isErrorShowing: Bool {
            state.error != nil
        }
        
    }
    
    public init(store: StoreOf<Search>) {
        self.store = store
        self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
    }
    
    @ViewBuilder
    func textField() -> some View {
        HStack {
            TextField("",
                      text: viewStore.binding(
                        get: \.textInput,
                        send: Search.Action.didChangeTextInput
                      ), axis: .vertical
            )
            .placeholder(when: viewStore.textInput.isEmpty) {
                Text("Search...")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.white)
            .cornerRadius(10)
            .frame(minHeight: 55)
        }
        .padding()
        .background(.thinMaterial)
    }
    
    public var body: some View {
        VStack {
            self.textField()
                .task(id: viewStore.textInput) {
                    do {
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 3)
                        await viewStore.send(.searchPlaces).finish()
                    } catch {}
                }
            
            if viewStore.searchResults.isEmpty {
                Spacer()
                Text("No Results")
                Spacer()
            } else {
                List {
                    ForEach(viewStore.searchResults) { place in
                        HStack {
                            Text("\(place.name), \(place.country)")
                            Spacer()
                        }.contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.exit(place.queryString))
                        }
                    }
                    
                }
                .listStyle(.plain)
            }
        }
        .alert(
            isPresented: viewStore.binding(
                get: \.isErrorShowing,
                send: Search.Action.dismissError
            )) {
                Alert(
                    title: Text("Something went wrong"),
                    message: Text(viewStore.errorMessage ?? ""),
                    dismissButton: Alert.Button.default(
                        Text("OK"),
                        action: { viewStore.send(.dismissError) }
                    )
                )
            }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            ZStack(alignment: alignment) {
                placeholder().opacity(shouldShow ? 1 : 0)
                self
            }
        }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(
            store: Store(
                initialState: Search.State(
                    textInput: "",
                    searchResults: Mock.place(count: 5)
                ),
                reducer: Search()
            )
        )
    }
}

