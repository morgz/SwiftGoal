//
//  EditMatchViewController.swift
//  SwiftGoal
//
//  Created by Martin Richter on 22/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import UIKit
//import ReactiveCocoa
import SnapKit
import RxCocoa
import RxSwift
import Result

class EditMatchViewController: UIViewController {

    private let viewModel: EditMatchViewModel

    private weak var homeGoalsLabel: UILabel!
    private weak var goalSeparatorLabel: UILabel!
    private weak var awayGoalsLabel: UILabel!
    private weak var homeGoalsStepper: UIStepper!
    private weak var awayGoalsStepper: UIStepper!
    private weak var homePlayersButton: UIButton!
    private weak var awayPlayersButton: UIButton!

    private let saveButtonItem: UIBarButtonItem
    
    let disposeBag = DisposeBag()



    init(viewModel: EditMatchViewModel) {
        
        self.viewModel = viewModel
        
        self.saveButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Save,
            target: nil,
            action: nil
        )
        
        super.init(nibName: nil, bundle: nil)

        // Set up navigation item
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: Selector("cancelButtonTapped")
        )
        navigationItem.rightBarButtonItem = self.saveButtonItem
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func loadView() {
        let view = UIView()

        view.backgroundColor = UIColor.whiteColor()

        let labelFont = UIFont(name: "OpenSans-Semibold", size: 70)

        let homeGoalsLabel = UILabel()
        homeGoalsLabel.font = labelFont
        view.addSubview(homeGoalsLabel)
        self.homeGoalsLabel = homeGoalsLabel

        let goalSeparatorLabel = UILabel()
        goalSeparatorLabel.font = labelFont
        goalSeparatorLabel.text = ":"
        view.addSubview(goalSeparatorLabel)
        self.goalSeparatorLabel = goalSeparatorLabel

        let awayGoalsLabel = UILabel()
        awayGoalsLabel.font = labelFont
        view.addSubview(awayGoalsLabel)
        self.awayGoalsLabel = awayGoalsLabel

        let homeGoalsStepper = UIStepper()
        view.addSubview(homeGoalsStepper)
        self.homeGoalsStepper = homeGoalsStepper

        let awayGoalsStepper = UIStepper()
        view.addSubview(awayGoalsStepper)
        self.awayGoalsStepper = awayGoalsStepper

        let homePlayersButton = UIButton(type: .System)
        homePlayersButton.titleLabel?.font = UIFont(name: "OpenSans", size: 15)
        homePlayersButton.addTarget(self,
            action: Selector("homePlayersButtonTapped"),
            forControlEvents: .TouchUpInside
        )
        view.addSubview(homePlayersButton)
        self.homePlayersButton = homePlayersButton

        let awayPlayersButton = UIButton(type: .System)
        awayPlayersButton.titleLabel?.font = UIFont(name: "OpenSans", size: 15)
        awayPlayersButton.addTarget(self,
            action: Selector("awayPlayersButtonTapped"),
            forControlEvents: .TouchUpInside
        )
        view.addSubview(awayPlayersButton)
        self.awayPlayersButton = awayPlayersButton

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActions()
        bindViewModel()
        makeConstraints()
    }

    // MARK: Bindings & Actions
    private func setupActions() {
        
        /////////
        //
        // Save Match
        //
        //
        self.saveButtonItem.rx_tap.subscribeOn(MainScheduler.instance).flatMap { [unowned self] _ -> Observable<Result<Bool,Break>> in
            return self.viewModel.saveMatch().observeOn(MainScheduler.instance)
                //Catching in an Inner FlatMap stops the button being subscription being terminated
                .mapToFailable()
        }.subscribeNext { (result) -> Void in
            switch result {
            case .Success(let output):
                print ("Success \(output)")
                self.dismissViewControllerAnimated(true, completion: nil)
            case .Failure(let breakError):
                if let error = breakError.error { print(error) }
                self.presentErrorMessage("The Match could not be saved")
            }
        }.addDisposableTo(disposeBag)
        
    }
    
    private func bindViewModel() {
        self.title = viewModel.title

        // Initial values
        self.homeGoalsStepper.value = Double(viewModel.homeGoals.value)
        self.awayGoalsStepper.value = Double(viewModel.awayGoals.value)
        
        // ReactiveCocoa:
// viewModel.homeGoals <~ homeGoalsStepper.signalProducer()

        self.homeGoalsStepper
            .rx_value
            .map{Int($0)}
            .bindTo(viewModel.homeGoals)
            .addDisposableTo(disposeBag)
        

        self.awayGoalsStepper
            .rx_value
            .map{Int($0)}
            .bindTo(viewModel.awayGoals)
            .addDisposableTo(self.disposeBag)
        
        // ReactiveCocoa:
//        viewModel.formattedHomeGoals.producer
//            .observeOn(UIScheduler())
//            .startWithNext({ [weak self] formattedHomeGoals in
//                self?.homeGoalsLabel.text = formattedHomeGoals
//            })
        
        // A driver is a type of Observable that can't error out and is performed on main Thread. For 'driving' UI from your data source
        // See: https://github.com/ReactiveX/RxSwift/blob/master/Documentation/Units.md
        
        viewModel.formattedHomeGoals.asDriver().drive(self.homeGoalsLabel.rx_text)
            .addDisposableTo(disposeBag)
        
        viewModel.formattedAwayGoals.asDriver().drive(self.awayGoalsLabel.rx_text)
            .addDisposableTo(self.disposeBag)

        
        /////////
        //
        // Players
        //
        //
        
        // ReactiveCocoa:
//        viewModel.homePlayersString.producer
//            .observeOn(UIScheduler())
//            .startWithNext({ [weak self] homePlayersString in
//                self?.homePlayersButton.setTitle(homePlayersString, forState: .Normal)
//                })
        
        self.viewModel.homePlayersString.asObservable().subscribeNext { [unowned self] (homePlayerString) -> Void in
            self.homePlayersButton.setTitle(homePlayerString, forState: .Normal)
        }.addDisposableTo(disposeBag)
        
        self.viewModel.awayPlayersString.asObservable().subscribeNext { [unowned self](awayPlayerString) -> Void in
            self.awayPlayersButton.setTitle(awayPlayerString, forState: .Normal)
        }.addDisposableTo(disposeBag)

        // ReactiveCocoa:
//        viewModel.inputIsValid.producer
//            .observeOn(UIScheduler())
//            .startWithNext({ [weak self] inputIsValid in
//                self?.saveButtonItem.enabled = inputIsValid
//            })
        
        viewModel.inputIsValid
            .asObservable()
            .bindTo(saveButtonItem.rx_enabled)
            .addDisposableTo(disposeBag)

        // ReactiveCocoa:
//        viewModel.saveAction.events.observeNext({ [weak self] event in
//            switch event {
//            case let .Next(success):
//                if success {
//                    self?.dismissViewControllerAnimated(true, completion: nil)
//                } else {
//                    self?.presentErrorMessage("The match could not be saved.")
//                }
//            case let .Failed(error):
//                self?.presentErrorMessage(error.localizedDescription)
//            default:
//                return
//            }
//        })
    }

    // MARK: Layout

    private func makeConstraints() {
        let superview = self.view

        homeGoalsLabel.snp_makeConstraints { make in
            make.trailing.equalTo(goalSeparatorLabel.snp_leading).offset(-10)
            make.baseline.equalTo(goalSeparatorLabel.snp_baseline)
        }

        goalSeparatorLabel.snp_makeConstraints { make in
            make.centerX.equalTo(superview.snp_centerX)
            make.centerY.equalTo(superview.snp_centerY).offset(-50)
        }

        awayGoalsLabel.snp_makeConstraints { make in
            make.leading.equalTo(goalSeparatorLabel.snp_trailing).offset(10)
            make.baseline.equalTo(goalSeparatorLabel.snp_baseline)
        }

        homeGoalsStepper.snp_makeConstraints { make in
            make.top.equalTo(goalSeparatorLabel.snp_bottom).offset(10)
            make.trailing.equalTo(homeGoalsLabel.snp_trailing)
        }

        awayGoalsStepper.snp_makeConstraints { make in
            make.top.equalTo(goalSeparatorLabel.snp_bottom).offset(10)
            make.leading.equalTo(awayGoalsLabel.snp_leading)
        }

        homePlayersButton.snp_makeConstraints { make in
            make.top.equalTo(homeGoalsStepper.snp_bottom).offset(30)
            make.leading.greaterThanOrEqualTo(superview.snp_leadingMargin)
            make.trailing.equalTo(homeGoalsLabel.snp_trailing)
        }

        awayPlayersButton.snp_makeConstraints { make in
            make.top.equalTo(awayGoalsStepper.snp_bottom).offset(30)
            make.leading.equalTo(awayGoalsLabel.snp_leading)
            make.trailing.lessThanOrEqualTo(superview.snp_trailingMargin)
        }
    }

    // MARK: User Interaction

    func cancelButtonTapped() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func homePlayersButtonTapped() {
        let homePlayersViewModel = viewModel.manageHomePlayersViewModel()
        let homePlayersViewController = ManagePlayersViewController(viewModel: homePlayersViewModel)
        self.navigationController?.pushViewController(homePlayersViewController, animated: true)
    }

    func awayPlayersButtonTapped() {
        let awayPlayersViewModel = viewModel.manageAwayPlayersViewModel()
        let awayPlayersViewController = ManagePlayersViewController(viewModel: awayPlayersViewModel)
        self.navigationController?.pushViewController(awayPlayersViewController, animated: true)
    }

    // MARK: Private Helpers

    func presentErrorMessage(message: String) {
        let alertController = UIAlertController(
            title: "Oops!",
            message: message,
            preferredStyle: .Alert
        )
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
