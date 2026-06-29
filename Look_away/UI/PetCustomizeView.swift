import AppKit
import SwiftUI

/// The "Customise Pet" palette, shown as a custom view inside an L2 submenu.
///
/// One place to pick a pet and a colour: a row of pet-shape thumbnails (rendered in the
/// currently-selected colour) on top, a row of colour swatches below. Selecting either
/// updates `AppSettings` immediately — while the menu is open the widget is peeking, so
/// changes preview live. `NSButton` clicks fire reliably inside menu item views (unlike
/// some SwiftUI controls), so the palette is built in AppKit with SwiftUI used only to
/// render the shape/swatch images via `ImageRenderer`.
final class PetCustomizeView: NSView {
    private let settings: AppSettings
    private var petButtons: [WidgetPet: NSButton] = [:]
    private var colorButtons: [WidgetColorOption: NSButton] = [:]
    private var specsButton: NSButton!

    private let thumb: CGFloat = 30
    private let cell: CGFloat = 40
    private let gap: CGFloat = 8
    private let pad: CGFloat = 16

    init(settings: AppSettings) {
        self.settings = settings
        super.init(frame: .zero)
        build()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let petRow = makeRow(WidgetPet.allCases.map { pet in
            let button = makeButton(action: #selector(selectPet(_:)), cornerRadius: 10)
            button.toolTip = pet.title
            button.image = petThumbnail(pet)
            petButtons[pet] = button
            return labeled(button, name: pet.title)
        })

        let colorRow = makeRow(WidgetColorOption.allCases.map { color in
            let button = makeButton(action: #selector(selectColor(_:)), cornerRadius: cell / 2)
            button.toolTip = color.title
            button.image = swatchImage(for: color)
            colorButtons[color] = button
            return button
        })

        specsButton = makeButton(action: #selector(toggleSpecs), cornerRadius: 10)
        specsButton.toolTip = "Specs"
        specsButton.image = specsImage()
        let specsRow = makeRow([specsButton])

        let stack = NSStackView(views: [
            makeLabel("Pets"), petRow,
            makeLabel("Color"), colorRow,
            makeLabel("Specs"), specsRow
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: pad),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -pad)
        ])
        frame = NSRect(origin: .zero, size: fittingSize)
    }

    private func makeRow(_ views: [NSView]) -> NSStackView {
        let row = NSStackView(views: views)
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = gap
        return row
    }

    /// A pet thumbnail with its name underneath.
    private func labeled(_ button: NSButton, name: String) -> NSView {
        let label = NSTextField(labelWithString: name)
        label.font = .systemFont(ofSize: 10)
        label.textColor = .labelColor
        label.alignment = .center
        let column = NSStackView(views: [button, label])
        column.orientation = .vertical
        column.alignment = .centerX
        column.spacing = 3
        return column
    }

    private func makeButton(action: Selector, cornerRadius: CGFloat) -> NSButton {
        let button = NSButton(frame: NSRect(x: 0, y: 0, width: cell, height: cell))
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
        button.title = ""
        button.target = self
        button.action = action
        button.wantsLayer = true
        button.layer?.cornerRadius = cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: cell).isActive = true
        button.heightAnchor.constraint(equalToConstant: cell).isActive = true
        return button
    }

    private func makeLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func refresh() {
        // Pet thumbnails are static (#2D2D2D), set once in build(); only their selection
        // ring changes here.
        for (pet, button) in petButtons {
            button.layer?.borderWidth = (pet == settings.widgetPet) ? 2.5 : 0
            button.layer?.borderColor = NSColor.controlAccentColor.cgColor
        }
        for (color, button) in colorButtons {
            button.layer?.borderWidth = (color == settings.widgetColor) ? 2.5 : 0
            button.layer?.borderColor = NSColor.labelColor.cgColor
        }
        specsButton.layer?.borderWidth = settings.specsEnabled ? 2.5 : 0
        specsButton.layer?.borderColor = NSColor.controlAccentColor.cgColor
    }

    @objc private func selectPet(_ sender: NSButton) {
        guard let pet = petButtons.first(where: { $0.value == sender })?.key else { return }
        settings.widgetPet = pet
        refresh()
    }

    @objc private func selectColor(_ sender: NSButton) {
        guard let color = colorButtons.first(where: { $0.value == sender })?.key else { return }
        settings.widgetColor = color
        refresh()
    }

    @objc private func toggleSpecs() {
        settings.specsEnabled.toggle()
        refresh()
    }

    // MARK: - Thumbnails

    private func petThumbnail(_ pet: WidgetPet) -> NSImage {
        let color = Color(hex: 0x2D2D2D)
        let shape: AnyView
        switch pet {
        case .bouncy: shape = AnyView(Circle().fill(color))
        case .boxy: shape = AnyView(RoundedRectangle(cornerRadius: 8).fill(color))
        case .flower: shape = AnyView(FlowerShape().fill(color))
        case .cat: shape = AnyView(CatShape().fill(color))
        }
        return render(shape.frame(width: thumb, height: thumb))
    }

    private func swatchImage(for color: WidgetColorOption) -> NSImage {
        return render(Circle().fill(color.color).frame(width: thumb, height: thumb))
    }

    private func specsImage() -> NSImage {
        let specs = SpecsShape()
            .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .frame(width: thumb, height: thumb * SpecsShape.referenceSize.height / SpecsShape.referenceSize.width)
        return render(specs)
    }

    private func render(_ view: some View) -> NSImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        return renderer.nsImage ?? NSImage()
    }
}
