//
//  CSTotalAmountInputVC.swift
//  SplitIt
//
//  Created by 홍승완 on 2023/10/16.
//

import UIKit
import RxSwift
import RxCocoa

class CSTotalAmountInputVC: UIViewController, CustomKeyboardDelegate {
    
    let inputTextRelay = BehaviorRelay<Int?>(value: 0)
    let customKeyboard = CustomKeyboard()
    
    var disposeBag = DisposeBag()
    let viewModel = CSTotalAmountInputVM()
    
    let header = NaviHeader()
    let titleMessage = UILabel()
    let totalAmountTextFiled = SPTextField()
    let textFiledNotice = UILabel()
    let nextButton = NewSPButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLayout()
        setAttribute()
        setBinding()
        textFieldCustomKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setKeyboardNotification()
        self.totalAmountTextFiled.becomeFirstResponder()
    }
    
    func textFieldCustomKeyboard() {
        
        totalAmountTextFiled.inputView = customKeyboard.inputView
        customKeyboard.delegate = self
        customKeyboard.setCurrentTextField(totalAmountTextFiled)
        
        customKeyboard.customKeyObservable
            .subscribe(onNext: { [weak self] value in
                self?.customKeyboard.handleInputValue(value)
                self?.inputTextRelay.accept(Int(self?.totalAmountTextFiled.text ?? ""))
            })
            .disposed(by: disposeBag)

        
    }
    
    
    func setAttribute() {
        view.backgroundColor = .SurfacePrimary
        
        header.do {
            $0.applyStyle(.csPrice)
            $0.setBackButton(viewController: self)
        }
        
        titleMessage.do {
            $0.text = "총 얼마를 사용하셨나요?"
            $0.font = .KoreanBody
            $0.textColor = .TextPrimary
        }
        
        totalAmountTextFiled.do {
            $0.applyStyle(.number)
            $0.font = .KoreanTitle3
        }
        
        textFiledNotice.do {
            $0.text = "설마, 천만원 이상을 쓰시진 않으셨죠?"
            $0.font = .KoreanCaption2
            $0.textColor = .TextSecondary
        }
        
        nextButton.do {
            $0.setTitle("다음으로", for: .normal)
            $0.applyStyle(style: .primaryMushroom, shape: .rounded)
        }
    }
    
    func setLayout() {
        [header,titleMessage,totalAmountTextFiled,textFiledNotice,nextButton].forEach {
            view.addSubview($0)
        }
        
        header.snp.makeConstraints {
            $0.height.equalTo(30)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.leading.trailing.equalToSuperview()
        }
        
        titleMessage.snp.makeConstraints {
            $0.top.equalTo(header.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
        }
        
        totalAmountTextFiled.snp.makeConstraints {
            $0.top.equalTo(titleMessage.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(60)
        }
        
        textFiledNotice.snp.makeConstraints {
            $0.top.equalTo(totalAmountTextFiled.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.leading.trailing.equalToSuperview().inset(30)
            $0.height.equalTo(48)
        }
    }
    
    func setBinding() {
        let input = CSTotalAmountInputVM.Input(nextButtonTapped: nextButton.rx.tap.asDriver(),
                                               totalAmount: totalAmountTextFiled.rx.text.orEmpty.asDriver(onErrorJustReturn: ""))
        let output = viewModel.transform(input: input)
        
        output.totalAmount
            .drive(totalAmountTextFiled.rx.text)
            .disposed(by: disposeBag)
        
        output.textFieldIsEmpty
            .drive(nextButton.buttonState)
            .disposed(by: disposeBag)
        
        output.showCSMemberInputView
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                let vc = CSMemberPageController()
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension CSTotalAmountInputVC: UITextFieldDelegate {
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
