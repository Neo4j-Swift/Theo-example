import UIKit

class ConnectViewController: UIViewController {

    @IBOutlet weak var hostNameTextField: UITextField?
    @IBOutlet weak var portTextField: UITextField?
    @IBOutlet weak var connectionTypeSegmentedControl: UISegmentedControl?
    @IBOutlet weak var userNameTextField: UITextField?
    @IBOutlet weak var passwordTextField: UITextField?
    @IBOutlet weak var connectButtonBottomLayoutConstraint: NSLayoutConstraint?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc
    func keyboardWillShow(_ notification: NSNotification) {
        if let animationDuration = notification.userInfo?["UIKeyboardAnimationDurationUserInfoKey"] as? CGFloat,
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            
            let duration = TimeInterval(animationDuration)
            connectButtonBottomLayoutConstraint?.constant = 20 + keyboardFrame.height
            UIView.animate(withDuration: duration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    @objc
    func keyboardWillHide(_ notification: NSNotification) {
        if let animationDuration = notification.userInfo?["UIKeyboardAnimationDurationUserInfoKey"] as? CGFloat {
            
            let duration = TimeInterval(animationDuration)
            connectButtonBottomLayoutConstraint?.constant = 20
            UIView.animate(withDuration: duration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard
            let hostNameTextFieldText = hostNameTextField?.text,
            let hostNameTextFieldPlaceholder = hostNameTextField?.placeholder,
            let portTextFieldText = portTextField?.text,
            let portTextFieldPlaceholder = portTextField?.placeholder,
            let userNameTextFieldText = userNameTextField?.text,
            let userNameTextFieldPlaceholder = userNameTextField?.placeholder,
            let passwordTextFieldText = passwordTextField?.text,
            let passwordTextFieldPlaceholder = passwordTextField?.placeholder else {
                return
        }
        
        let hostname = hostNameTextFieldText == "" ? hostNameTextFieldPlaceholder : hostNameTextFieldText

        let portString = portTextFieldText == "" ? portTextFieldPlaceholder : portTextFieldText
        let port = Int(portString) ?? 7687
        let username = userNameTextFieldText == "" ? userNameTextFieldPlaceholder : userNameTextFieldText
        let password = passwordTextFieldText == "" ? passwordTextFieldPlaceholder : passwordTextFieldText
        
        let config = ConnectionConfig(host: hostname, port: port, username: username, password: password)
        
        if let queryVc = segue.destination as? QueryViewController {
            queryVc.connectionConfig = config
        }
    }

}

extension ConnectViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool  {
        textField.resignFirstResponder()
        return true
    }
    
    
}
