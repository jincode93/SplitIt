//
//  JSDetailVC.swift
//  SplitIt
//
//  Created by 주환 on 2023/10/30.
//

import UIKit
import Reusable
import Then
import SnapKit
import RxSwift
import RxCocoa
import RxAppState
import RealmSwift

final class JSDetailVC: UIViewController, UIScrollViewDelegate, SPAlertDelegate {
    
    var disposeBag = DisposeBag()
    var viewModel = JSDetailVM()
    
    let headerView = SPNavigationBar()
    let collectionView = UITableView(frame: .zero)
    let nextButton = NewSPButton()
    let splitTitleTF = SPTextField()
    let textFiledCounter = UILabel()
    let titleLabel = UILabel()
    let alert = SPAlertController()
    
    var cellHeight = [0.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAttribute()
        setLayout()
        setBinding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setKeyboardNotification()
        super.viewWillAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setAttribute() {
        view.backgroundColor = .SurfaceBrandCalmshell
        
        headerView.do {
            $0.applyStyle(style: .splitEditToAlert, vc: self)
        }
        
        titleLabel.do {
            $0.text = "이름이 있으면 나중에 찾기 쉬워요"
            $0.textColor = .TextPrimary
            $0.font = .KoreanBody
        }
        
        splitTitleTF.do {
            $0.applyStyle(.normal)
            $0.font = .KoreanCaption1
            $0.textColor = .TextPrimary
            $0.placeholder = "ex) 팀 회식, 생일파티, 집들이"
            $0.autocorrectionType = .no
            $0.spellCheckingType = .no
        }
        
        textFiledCounter.do {
            $0.font = .KoreanCaption1
            $0.textColor = .TextSecondary
        }
        
        collectionView.do {
            $0.backgroundColor = .SurfaceBrandCalmshell
            $0.register(cellType: JSDetailCell.self)
            $0.rowHeight = 208
            let tapGesture = UITapGestureRecognizer()
            tapGesture.rx.event.bind { [weak self] _ in
                guard let self = self else { return }
                self.view.endEditing(true)
            }.disposed(by: disposeBag)
            
            $0.addGestureRecognizer(tapGesture)
            tapGesture.delegate = self
        }
        
        nextButton.do {
            $0.buttonState.accept(true)
            $0.applyStyle(style: .primaryWatermelon, shape: .rounded)
            $0.setTitle("영수증에 반영하기", for: .normal)
        }
    }
    
    func setLayout() {
        let divider = UIView().then {
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.BorderDeactivate.cgColor
        }
        
        [headerView, titleLabel, splitTitleTF, textFiledCounter, divider, collectionView, nextButton].forEach {
            view.addSubview($0)
        }
        
        headerView.snp.makeConstraints {
            $0.height.equalTo(30)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            $0.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(38)
        }
        
        splitTitleTF.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(46)
        }
        
        textFiledCounter.snp.makeConstraints {
            $0.top.equalTo(splitTitleTF.snp.bottom).offset(6)
            $0.trailing.equalTo(splitTitleTF.snp.trailing).inset(5)
        }
        
        divider.snp.makeConstraints {
            $0.top.equalTo(splitTitleTF.snp.bottom).offset(40)
            $0.height.equalTo(1)
            $0.leading.trailing.equalToSuperview().inset(30)
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40)
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(48)
        }
        
        collectionView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.top.equalTo(divider.snp.bottom).offset(24)
            $0.bottom.equalTo(nextButton.snp.top)
        }
        
    }
    
    func setBinding() {
        viewModel.csinfoList
            .drive(collectionView.rx.items(cellIdentifier: "JSDetailCell", cellType: JSDetailCell.self)) { [weak self] idx, item, cell in
                guard let self = self else { return }
                let memberCount = self.viewModel.memberCount()
                let exclCount = self.viewModel.exclItemCount()
                cell.configure(csinfo: item, csMemberCount: memberCount[idx], exclItemCount: exclCount[idx])
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
                
                let size = cell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                self.cellHeight.append(size)
            }
            .disposed(by: disposeBag)
        
        let input = JSDetailVM.Input(viewDidLoad: self.rx.viewWillAppear,
                                     nextButtonTapped: nextButton.rx.tap,
                                     title: splitTitleTF.rx.text.orEmpty.asDriver(),
                                     csEditTapped: collectionView.rx.itemSelected)
        
        let output = viewModel.transform(input: input)
        
        output.titleCount
            .drive(textFiledCounter.rx.text)
            .disposed(by: disposeBag)
        
        output.textFieldIsValid
            .distinctUntilChanged()
            .drive(onNext: { [weak self] isValid in
                guard let self = self else { return }
                self.textFiledCounter.textColor = isValid
                ? .TextSecondary
                : .AppColorStatusError
            })
            .disposed(by: disposeBag)
        
        output.splitTitle
            .drive(splitTitleTF.rx.text)
            .disposed(by: disposeBag)
        
        output.pushCSEditView
            .drive(onNext: { [weak self] csinfoIdx in
                guard let self = self else { return }
                let vc = EditCSListVC(csinfoIdx: csinfoIdx)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
        
        output.pushNextView
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        headerView.leftButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                showAlert(view: self.alert,
                          type: .warnNormal,
                          title: "수정을 중단하시겠어요?",
                          descriptions: "지금까지 수정하신 내역이 사라져요",
                          leftButtonTitle: "취 소",
                          rightButtonTitle: "중단하기")
            })
            .disposed(by: disposeBag)
        
        alert.rightButtonTapSubject
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
}

extension JSDetailVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return (touch.view == self.collectionView)
    }
}

extension JSDetailVC: UITextFieldDelegate {
    func setKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight: CGFloat
            keyboardHeight = keyboardSize.height - self.view.safeAreaInsets.bottom
            self.nextButton.snp.updateConstraints {
                $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(keyboardHeight + 26)
            }
        }
    }
    
    @objc private func keyboardWillHide() {
        self.nextButton.snp.updateConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    func setKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func setKeyboardObserverRemove() {
        NotificationCenter.default.removeObserver(self)
    }
}
