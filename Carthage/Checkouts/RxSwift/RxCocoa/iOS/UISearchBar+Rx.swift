//
//  UISearchBar+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 3/28/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Foundation
#if !RX_NO_MODULE
import RxSwift
#endif
import UIKit



extension UISearchBar {
    
    /**
    Reactive wrapper for `delegate`.
    
    For more information take a look at `DelegateProxyType` protocol documentation.
    */
    public var rx_delegate: DelegateProxy {
        return proxyForObject(RxSearchBarDelegateProxy.self, self)
    }
    
    /**
    Reactive wrapper for `text` property.
    */
    public var rx_text: ControlProperty<String> {
        let source: Observable<String> = Observable.deferred { [weak self] () -> Observable<String> in
            let text = self?.text ?? ""
            
            return (self?.rx_delegate.observe("searchBar:textDidChange:") ?? Observable.empty())
                    .map { a in
                        return a[1] as? String ?? ""
                    }
                    .startWith(text)
        }

        let bindingObserver = UIBindingObserver(UIElement: self) { (searchBar, text: String) in
            searchBar.text = text
        }
        
        return ControlProperty(values: source, valueSink: bindingObserver)
    }
}

#endif
