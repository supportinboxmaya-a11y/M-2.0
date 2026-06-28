
from .registry import ToolRegistry
from .web.google_search import GoogleSearch
from .web.web_scraper import WebScraper
from .web.youtube_tool import YouTubeTool
from .web.browser_tool import BrowserTool
from .files.file_manager import FileManager
from .files.reader import FileReader
from .files.writer import FileWriter
from .files.pdf_tool import PDFTool
from .code.code_runner import CodeRunner
from .code.calculator_tool import CalculatorTool
from .system.shell import ShellTool
from .system.terminal import TerminalTool
from .system.process_manager import ProcessManager
from .media.media_tool import MediaTool
from .media.image_gen_tool import ImageGenTool
from .communication.email_tool import EmailTool

class ToolManager:
    def __init__(self):
        self.registry = ToolRegistry()
        self._register_all()

    def _register_all(self):
        search = GoogleSearch()
        scraper = WebScraper()
        youtube = YouTubeTool()
        browser = BrowserTool()
        fm = FileManager()
        reader = FileReader()
        writer = FileWriter()
        pdf = PDFTool()
        code = CodeRunner()
        calc = CalculatorTool()
        shell = ShellTool()
        terminal = TerminalTool()
        pm = ProcessManager()
        media = MediaTool()
        image_gen = ImageGenTool()
        email_tool = EmailTool()

        self.registry.register("web_search", search.search, "Search the web")
        self.registry.register("web_scrape", scraper.scrape, "Scrape a web page")
        self.registry.register("youtube_search", youtube.search, "Search YouTube")
        self.registry.register("youtube_transcript", youtube.get_transcript, "Get YouTube transcript")
        self.registry.register("browser_open", browser.open, "Open URL in browser")
        self.registry.register("browser_click", browser.click, "Click element")
        self.registry.register("browser_type", browser.type_text, "Type in input")
        self.registry.register("browser_text", browser.get_text, "Get page text")
        self.registry.register("browser_screenshot", browser.screenshot, "Take screenshot")
        self.registry.register("browser_google", browser.search_google, "Google via browser")
        self.registry.register("read_file", reader.read, "Read a file")
        self.registry.register("write_file", writer.write, "Write to a file")
        self.registry.register("list_files", fm.list_files, "List files")
        self.registry.register("delete_file", fm.delete, "Delete a file")
        self.registry.register("read_pdf", pdf.run, "Read PDF file")
        self.registry.register("run_code", code.run, "Execute Python code")
        self.registry.register("calculate", calc.run, "Calculate math")
        self.registry.register("run_shell", shell.run, "Run shell command")
        self.registry.register("run_terminal", terminal.execute, "Execute terminal")
        self.registry.register("list_processes", pm.list_processes, "List processes")
        self.registry.register("image_tool", media.run, "Image operations")
        self.registry.register("generate_image", image_gen.run, "Generate AI image")
        self.registry.register("email", email_tool.run, "Send/read email")

    def get_registry(self):
        return self.registry
