//
//  Promise.swift
//  CleanArchitecture
//
//  Created by Penas Amor, Alberto on 18/4/18.
//  Copyright © 2018 Alberto. All rights reserved.
//
import Foundation

typealias Reject = (_ error:Error) -> Void
typealias Resolve = (_ data:Any) -> Void
typealias Thenable = (_ data:Any) -> Promise
typealias FinalThenable = (_ data:Any) -> Void

enum PromiseState {
    case pending, fulfilled, rejected
}
//TODO: states, el then devuelve nil(si devuelve otra cosa, no va a funcionar)
//TODO: spec: https://github.com/promises-aplus/promises-spec
//meter params...???
//TODO: quitar dependencia de main thread...
class Promise {
    
    private var thens:Array<Thenable>
    private var finalThen:FinalThenable?
    private var reject:Reject?
    private var state:PromiseState
    private let work:Work
    
    init(work:Work) {
        self.thens = Array()
        self.state = .pending
        self.work = work
    }
    
    func then(resolve:@escaping Thenable) -> Promise {
        print("then callback setted")
        if thens.isEmpty {
            self.thens.append(resolve)
            start()
        }else{
            self.thens.append(resolve)
        }
        return self
    }
    
    //TODO: test with one simple call
    func finally(resolveFinal:@escaping FinalThenable) -> Promise {
        print("finally callback setted")
        if self.finalThen != nil {
            assertionFailure("finally can only be called once per promise")
        }
        self.finalThen = resolveFinal
        if thens.isEmpty {
            start()
        }
        return self
    }
    
    func error(reject:@escaping Reject) {
        print("error callback setted")
        self.reject = reject
    }
    
    private func start() {
        print("deferred")
        //TODO: puta mierda main!!!!, a ver como se desacopla
        //If works with 0 better than 0.001, OJO OJO OJO, IGUAL NO FUNCIONA SIEMPRE... HABRÁ QUE ASEGURAR COMO FUNCIONA EL RUNLOOP DE APPLE
        //TODO: RUN LOOP https://stackoverflow.com/questions/3731881/why-is-my-cllocationmanager-delegate-not-getting-called
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            do{
                print("start")
                try self.work.run(resolve: self.innerResolver, reject: self.innerReject)
            }catch {
                print("start catched error: \(error)")
                self.innerReject(error: error)
            }
        }
    }
    
    //Ojo este inner resolver debbe ser diff
    private func innerResolver(_ data:Any) -> Void {
        if state != .pending{
            print("innerResolver returning with state \(state)")
            return
        }
        print("innerResolver thens.count \(thens.count)")
        if self.thens.count > 0 {
            let then:Thenable = self.thens[0]
            self.thens.removeFirst(1)
            let nextPromise = then(data)
            print("nextPromise start")
            nextPromise.reject = self.reject
            nextPromise.thens = self.thens
            nextPromise.finalThen = self.finalThen
            nextPromise.start()        
            state = .fulfilled
        }else if let finalThen = finalThen {
            finalThen(data)
            state = .fulfilled
        }
    }
    
    private func innerReject(error:Error) -> Void {
        if state != .pending{
            print("innerError returning with state \(state)")
            return
        }
        self.reject?(error)
        state = .rejected
    }
    
}

