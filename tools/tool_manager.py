
from .registry import ToolRegistry
from .web.google_search import GoogleSearch
from .web.web_scraper import WebScraper
from .web.youtube_tool import YouTubeTool
from .web.browser_tool import BrowserTool
from .web.rest_api_tool import RestApiTool
from .web.github_tool import GitHubTool
from .web.graphql_tool import GraphQLTool
from .files.file_manager import FileManager
from .files.reader import FileReader
from .files.writer import FileWriter
from .files.pdf_tool import PDFTool
from .files.zip_tool import ZipTool
from .files.csv_tool import CsvTool
from .files.json_tool import JsonTool
from .files.excel_tool import ExcelTool
from .data.database_tool import DatabaseTool
from .code.code_runner import CodeRunner
from .code.calculator_tool import CalculatorTool
from .code.git_tool import GitTool
from .system.shell import ShellTool
from .system.terminal import TerminalTool
from .system.process_manager import ProcessManager
from .media.media_tool import MediaTool
from .media.image_gen_tool import ImageGenTool
from .media.vision_tool import VisionTool
from .media.tts_tool import TTSTool
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
        rest_api = RestApiTool()
        graphql = GraphQLTool()
        git = GitTool()
        github = GitHubTool()
        fm = FileManager()
        reader = FileReader()
        writer = FileWriter()
        pdf = PDFTool()
        zip_tool = ZipTool()
        csv_tool = CsvTool()
        json_tool = JsonTool()
        excel_tool = ExcelTool()
        db_tool = DatabaseTool()
        code = CodeRunner()
        calc = CalculatorTool()
        shell = ShellTool()
        terminal = TerminalTool()
        pm = ProcessManager()
        media = MediaTool()
        image_gen = ImageGenTool()
        vision = VisionTool()
        tts = TTSTool()
        email_tool = EmailTool()

        self.registry.register("web_search", search.search, "Search the web", category="web")
        self.registry.register("web_scrape", scraper.scrape, "Scrape a web page", category="web")
        self.registry.register("youtube_search", youtube.search, "Search YouTube", category="web")
        self.registry.register("youtube_transcript", youtube.get_transcript, "Get YouTube transcript", category="web")
        self.registry.register("browser_open", browser.open, "Open URL in browser", category="web")
        self.registry.register("browser_click", browser.click, "Click element", category="web")
        self.registry.register("browser_type", browser.type_text, "Type in input", category="web")
        self.registry.register("browser_text", browser.get_text, "Get page text", category="web")
        self.registry.register("browser_screenshot", browser.screenshot, "Take screenshot", category="web")
        self.registry.register("browser_google", browser.search_google, "Google via browser", category="web")
        self.registry.register("browser_click_visually", browser.click_visually, "Click an element by visual description when no CSS selector works (vision-guided)", category="web")
        self.registry.register("browser_look", browser.look, "Ask a free-form question about what's currently visible on the page (vision)", category="web")
        self.registry.register("rest_api_request", rest_api.request, "Make an HTTP request to any REST API", category="web")
        self.registry.register("github_get_repo", github.get_repo, "Get GitHub repo info (public API)", category="developer")
        self.registry.register("github_list_files", github.list_files, "List files in a GitHub repo path", category="developer")
        self.registry.register("github_get_file", github.get_file, "Read a file's content from a GitHub repo", category="developer")
        self.registry.register("graphql_query", graphql.query, "Query any GraphQL API endpoint", category="web")
        self.registry.register("git_init", git.init, "Initialize a git repo in a workspace directory", category="developer")
        self.registry.register("git_status", git.status, "Show git working tree status", category="developer")
        self.registry.register("git_log", git.log, "Show recent git commit history", category="developer")
        self.registry.register("git_diff", git.diff, "Show git changes (staged=True for staged)", category="developer")
        self.registry.register("git_add", git.add, "Stage files for commit", category="developer")
        self.registry.register("git_commit", git.commit, "Commit staged changes with a message", category="developer")
        self.registry.register("git_branch", git.branch, "List branches or create+switch to a new one", category="developer")
        self.registry.register("git_checkout", git.checkout, "Switch to an existing git branch", category="developer")
        self.registry.register("git_merge", git.merge, "Merge a branch into the current one (conflict-safe)", category="developer")
        self.registry.register("read_file", reader.read, "Read a file", category="file")
        self.registry.register("write_file", writer.write, "Write to a file", category="file")
        self.registry.register("list_files", fm.list_files, "List files", category="file")
        self.registry.register("delete_file", fm.delete, "Delete a file", category="file")
        self.registry.register("read_pdf", pdf.run, "Read PDF file", category="file")
        self.registry.register("zip_create", zip_tool.create, "Create a zip archive from files", category="file")
        self.registry.register("zip_extract", zip_tool.extract, "Extract a zip archive", category="file")
        self.registry.register("zip_list", zip_tool.list_contents, "List a zip archive's contents", category="file")
        self.registry.register("csv_read", csv_tool.read, "Read rows from a CSV file", category="file")
        self.registry.register("csv_write", csv_tool.write, "Write rows to a CSV file", category="file")
        self.registry.register("json_read", json_tool.read, "Read (and optionally query) a JSON file", category="file")
        self.registry.register("json_write", json_tool.write, "Write data to a JSON file", category="file")
        self.registry.register("excel_read", excel_tool.read, "Read rows from an Excel (.xlsx) file", category="file")
        self.registry.register("excel_write", excel_tool.write, "Write rows to an Excel (.xlsx) file", category="file")
        self.registry.register("database_query", db_tool.run_query, "Run a SQL query against the agent's own database", category="developer")
        self.registry.register("database_list_tables", db_tool.list_tables, "List tables in the agent's own database", category="developer")
        self.registry.register("run_code", code.run, "Execute Python code", category="developer")
        self.registry.register("calculate", calc.run, "Calculate math", category="developer")
        self.registry.register("run_shell", shell.run, "Run shell command", category="system")
        self.registry.register("run_terminal", terminal.execute, "Execute terminal", category="system")
        self.registry.register("list_processes", pm.list_processes, "List processes", category="system")
        self.registry.register("image_tool", media.run, "Image operations", category="media")
        self.registry.register("generate_image", image_gen.run, "Generate AI image (saved to workspace)", category="media")
        self.registry.register("vision_analyze", vision.run, "Analyze an image with a multimodal LLM (base64/data URL/workspace path)", category="media")
        self.registry.register("ocr_image", lambda image: vision.run(action="ocr", image=image), "Extract text from an image (OCR)", category="media")
        self.registry.register("text_to_speech", tts.run, "Convert text to spoken audio (saved to workspace/audio)", category="media")
        self.registry.register("email", email_tool.run, "Send/read email", category="communication")

    def get_registry(self):
        return self.registry
