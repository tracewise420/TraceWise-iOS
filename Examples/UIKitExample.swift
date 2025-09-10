import UIKit
import TraceWiseSDK

class ProductViewController: UIViewController {
    private let sdk: TraceWiseSDK
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var resultLabel: UILabel!
    
    init() {
        let config = SDKConfig(
            baseURL: "https://trace-wise.eu/api",
            enableLogging: true
        )
        self.sdk = TraceWiseSDK(config: config)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        let config = SDKConfig(
            baseURL: "https://trace-wise.eu/api",
            enableLogging: true
        )
        self.sdk = TraceWiseSDK(config: config)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "TraceWise SDK Demo"
        view.backgroundColor = .systemBackground
        
        // Setup default URL
        urlTextField?.text = "https://id.gs1.org/01/04012345678905/21/SN123456"
        
        // Setup result label
        resultLabel?.numberOfLines = 0
        resultLabel?.text = "Enter a GS1 Digital Link URL and tap Scan"
    }
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        guard let url = urlTextField?.text, !url.isEmpty else {
            showError("Please enter a valid URL")
            return
        }
        
        Task {
            await scanProduct(url: url)
        }
    }
    
    private func scanProduct(url: String) async {
        await MainActor.run {
            scanButton?.isEnabled = false
            loadingIndicator?.startAnimating()
            resultLabel?.text = "Scanning product..."
        }
        
        do {
            // Parse Digital Link
            let ids = try sdk.parseDigitalLink(url)
            
            // Get product (exact Trello task signature)
            let product = try await sdk.getProduct(gtin: ids.gtin, serial: ids.serial)
            
            // Register product to user (exact Trello task signature)
            try await sdk.registerProduct(userId: "demo-user", product: product)
            
            // Add lifecycle event (exact Trello task signature)
            let event = LifecycleEvent(
                gtin: ids.gtin,
                serial: ids.serial,
                bizStep: "scanned",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                details: ["app": "iOS Demo UIKit"]
            )
            try await sdk.addLifecycleEvent(event: event)
            
            await MainActor.run {
                showProductInfo(product)
            }
            
        } catch {
            await MainActor.run {
                showError(error.localizedDescription)
            }
        }
        
        await MainActor.run {
            scanButton?.isEnabled = true
            loadingIndicator?.stopAnimating()
        }
    }
    
    private func showProductInfo(_ product: Product) {
        var info = "✅ Product Found!\n\n"
        info += "Name: \(product.name)\n"
        info += "GTIN: \(product.gtin)\n"
        
        if let serial = product.serial {
            info += "Serial: \(serial)\n"
        }
        
        if let manufacturer = product.manufacturer {
            info += "Manufacturer: \(manufacturer)\n"
        }
        
        info += "\n✅ Registered to user\n✅ Lifecycle event added"
        
        resultLabel?.text = info
    }
    
    private func showError(_ message: String) {
        resultLabel?.text = "❌ Error: \(message)"
    }
}

// MARK: - Programmatic UI Setup (if not using Storyboard)
extension ProductViewController {
    func setupProgrammaticUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        urlTextField = UITextField()
        urlTextField.borderStyle = .roundedRect
        urlTextField.placeholder = "Enter GS1 Digital Link URL"
        urlTextField.text = "https://id.gs1.org/01/04012345678905/21/SN123456"
        
        scanButton = UIButton(type: .system)
        scanButton.setTitle("Scan Product", for: .normal)
        scanButton.backgroundColor = .systemBlue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 8
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.hidesWhenStopped = true
        
        resultLabel = UILabel()
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        resultLabel.text = "Enter a GS1 Digital Link URL and tap Scan"
        
        stackView.addArrangedSubview(urlTextField)
        stackView.addArrangedSubview(scanButton)
        stackView.addArrangedSubview(loadingIndicator)
        stackView.addArrangedSubview(resultLabel)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            scanButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}