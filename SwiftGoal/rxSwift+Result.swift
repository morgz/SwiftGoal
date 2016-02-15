//
//  rxSwift+Result.swift
//  SwiftGoal
//
//  Created by Daniel Morgz on 15/02/2016.
//  Copyright © 2016 Martin Richter. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Result

public enum Break: ErrorType{
    case Cancelled
    case Timeout
    case Unknown
    case Error(ErrorType)
    
    var error: ErrorType? {
        switch self {
        case .Error(let error): return error
        default: return nil
        }
    }
    
    var nsError:  NSError? {
        guard let error = error else { return nil }
        guard error.dynamicType == NSError.self else { return nil }
        return error as NSError
    }
}

extension ObservableType {
    @warn_unused_result(message="http://git.io/rxs.uo")
    public func mapToFailable() -> Observable<Result<E, Break>>{
        return self
            .map(Result<E, Break>.Success)
            
            // catch error map to Result.Failure(Break.Error(error)), so the signal on this subject will not interrupt its super subject
            .catchError{  Observable.just(.Failure(.Error($0))) }
    }
}