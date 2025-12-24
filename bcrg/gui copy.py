from ttkbootstrap import Style
from ttkbootstrap.constants import *
from tkinter import filedialog, messagebox
import tkinter as tk
from tkinter import ttk


class TemplateGeneratorApp:
    def __init__(self, master):
        self.master = master
        master.title("Template Generator")
        master.geometry("600x500")
        master.resizable(False, False)

        # --- Variables ---
        self.template_path = tk.StringVar()
        self.output_dir = tk.StringVar()
        self.resolution_w = tk.StringVar(value="1920")
        self.resolution_h = tk.StringVar(value="1080")
        self.clicks_h = tk.StringVar(value="1.0")
        self.clicks_v = tk.StringVar(value="1.0")
        self.output_mode = tk.StringVar(value="dir")

        # --- Create Widgets ---
        self._create_widgets()

    def _create_widgets(self):
        # Main container with padding
        container = ttk.Frame(self.master, padding=20)
        container.pack(fill='both', expand=True)

        # Title
        title = ttk.Label(
            container, 
            text="Template Generator", 
            font=('Ubuntu', 18, 'bold'),
            bootstyle="inverse-primary"
        )
        title.pack(pady=(0, 20))

        # --- 1. Select Template File ---
        file_container = ttk.Frame(container, bootstyle="light")
        file_container.pack(fill='x', pady=(0, 10))
        
        ttk.Label(file_container, text="Template File", font=('Ubuntu', 11, 'bold'), bootstyle="primary").pack(anchor='w', pady=(5, 5), padx=10)
        
        file_frame = ttk.Frame(file_container, padding=(10, 5, 10, 10))
        file_frame.pack(fill='x')
        
        ttk.Entry(file_frame, textvariable=self.template_path).pack(side='left', fill='x', expand=True, padx=(0, 10))
        ttk.Button(file_frame, text="Browse", command=self.select_template, bootstyle="secondary").pack(side='right')

        # --- 2. Select Output Directory ---
        output_container = ttk.Frame(container, bootstyle="light")
        output_container.pack(fill='x', pady=(0, 10))
        
        ttk.Label(output_container, text="Output Directory", font=('Ubuntu', 11, 'bold'), bootstyle="primary").pack(anchor='w', pady=(5, 5), padx=10)
        
        output_frame = ttk.Frame(output_container, padding=(10, 5, 10, 10))
        output_frame.pack(fill='x')
        
        ttk.Entry(output_frame, textvariable=self.output_dir).pack(side='left', fill='x', expand=True, padx=(0, 10))
        ttk.Button(output_frame, text="Browse", command=self.select_output_dir, bootstyle="secondary").pack(side='right')
        
        # --- 3. Set Resolution (Width / Height) ---
        res_container = ttk.Frame(container, bootstyle="light")
        res_container.pack(fill='x', pady=(0, 10))
        
        ttk.Label(res_container, text="Resolution", font=('Ubuntu', 11, 'bold'), bootstyle="primary").pack(anchor='w', pady=(5, 5), padx=10)
        
        res_frame = ttk.Frame(res_container, padding=(10, 5, 10, 10))
        res_frame.pack()
        
        ttk.Label(res_frame, text="Width:").pack(side='left', padx=(0, 5))
        ttk.Entry(res_frame, textvariable=self.resolution_w, width=10).pack(side='left', padx=(0, 15))
        ttk.Label(res_frame, text="Height:").pack(side='left', padx=(0, 5))
        ttk.Entry(res_frame, textvariable=self.resolution_h, width=10).pack(side='left')

        # --- 4. Set Clicks (Horizontal / Vertical) ---
        clicks_container = ttk.Frame(container, bootstyle="light")
        clicks_container.pack(fill='x', pady=(0, 10))
        
        ttk.Label(clicks_container, text="Clicks", font=('Ubuntu', 11, 'bold'), bootstyle="primary").pack(anchor='w', pady=(5, 5), padx=10)
        
        clicks_frame = ttk.Frame(clicks_container, padding=(10, 5, 10, 10))
        clicks_frame.pack()
        
        ttk.Label(clicks_frame, text="Horizontal:").pack(side='left', padx=(0, 5))
        ttk.Entry(clicks_frame, textvariable=self.clicks_h, width=10).pack(side='left', padx=(0, 15))
        ttk.Label(clicks_frame, text="Vertical:").pack(side='left', padx=(0, 5))
        ttk.Entry(clicks_frame, textvariable=self.clicks_v, width=10).pack(side='left')

        # --- 5. Output Mode (Radiobutton Group) ---
        mode_container = ttk.Frame(container, bootstyle="light")
        mode_container.pack(fill='x', pady=(0, 20))
        
        ttk.Label(mode_container, text="Output Mode", font=('Ubuntu', 11, 'bold'), bootstyle="primary").pack(anchor='w', pady=(5, 5), padx=10)
        
        mode_frame = ttk.Frame(mode_container, padding=(10, 5, 10, 10))
        mode_frame.pack()
        
        ttk.Radiobutton(mode_frame, text="Directory", variable=self.output_mode, value="dir", bootstyle="primary-toolbutton").pack(side='left', padx=10)
        ttk.Radiobutton(mode_frame, text="TAR Archive", variable=self.output_mode, value="tar", bootstyle="primary-toolbutton").pack(side='left', padx=10)
        ttk.Radiobutton(mode_frame, text="ZIP Archive", variable=self.output_mode, value="zip", bootstyle="primary-toolbutton").pack(side='left', padx=10)

        # --- 6. Generate Button ---
        ttk.Button(
            container, 
            text="GENERATE TEMPLATE", 
            command=self.generate,
            bootstyle="success",
            width=30
        ).pack(pady=10)

    def select_template(self):
        file_path = filedialog.askopenfilename(
            defaultextension=".txt",
            filetypes=[("Template files", "*.txt"), ("All files", "*.*")],
            title="Select Template File"
        )
        if file_path:
            self.template_path.set(file_path)

    def select_output_dir(self):
        dir_path = filedialog.askdirectory(title="Select Output Directory")
        if dir_path:
            self.output_dir.set(dir_path)

    def generate(self):
        if not self.template_path.get() or not self.output_dir.get():
            messagebox.showerror("Error", "Please select both a Template File and an Output Directory.")
            return

        try:
            w = int(self.resolution_w.get())
            h = int(self.resolution_h.get())
            ch = float(self.clicks_h.get())
            cv = float(self.clicks_v.get())
        except ValueError:
            messagebox.showerror("Error", "Resolution (W/H) must be integers, and Clicks (H/V) must be valid numbers.")
            return

        data = {
            "Template File": self.template_path.get(),
            "Output Directory": self.output_dir.get(),
            "Resolution": f"{w}x{h}",
            "Clicks (H/V)": f"{ch} / {cv}",
            "Output Mode": self.output_mode.get().upper(),
        }

        info_message = "\n".join([f"{k}: {v}" for k, v in data.items()])
        messagebox.showinfo(
            "Generation Started",
            f"Template generation simulated with the following parameters:\n\n{info_message}"
        )


if __name__ == '__main__':
    # Створюємо root вікно
    root = tk.Tk()
    
    # Виправлення DPI для високої роздільної здатності екранів
    root.tk.call('tk', 'scaling', 2.0)
    
    # Встановлюємо стандартні шрифти з антиаліасингом
    default_font = ('Ubuntu', 10)  # або 'DejaVu Sans', 'Noto Sans'
    root.option_add('*Font', default_font)
    
    # Застосовуємо ttkbootstrap тему
    # Доступні теми: cosmo, flatly, litera, minty, lumen, sandstone, yeti, pulse, 
    # united, morph, journal, darkly, superhero, solar, cyborg, vapor, simplex, cerculean
    style = Style(theme='cosmo')
    
    app = TemplateGeneratorApp(root)
    root.mainloop()