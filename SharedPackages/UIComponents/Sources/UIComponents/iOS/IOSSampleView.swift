//
//  MacSampleView.swift
//  UIComponents
//
//  Created by Fernando Bunn on 31/03/2025.
//


#if os(iOS)
import DesignResourcesKit
import SwiftUI

public struct IOSSampleView: View {

    public init() { }
    
    public var body: some View {
        Text("I'm on iOS")
            .daxCaption()
    }
}

#Preview {
    IOSSampleView()
}


#endif
