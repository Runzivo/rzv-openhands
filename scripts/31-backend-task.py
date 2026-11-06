"""Run one task through an OpenHands Agent Server reached over the rzv-openhands-backend tunnel.

    python 31-backend-task.py <backend-url> <api-key-file> <model>

The model's provider key is not sent from here: the agent server in the sandbox reads it
from the mode 600 file that `rzv-openhands-backend key` wrote. Exits 0 when the agent
has written /workspace/backend-ok.txt with the expected text.
"""

import sys
from pathlib import Path

from openhands.sdk import LLM, Conversation, Workspace
from openhands.tools.preset.default import get_default_agent

url, key_file, model = sys.argv[1:4]
api_key = Path(key_file).read_text().strip()
workspace = Workspace(host=url, api_key=api_key, working_dir="/workspace")
print("server:", workspace.execute_command("uname -sm").stdout.strip())

llm = LLM(usage_id="agent", model=model)
agent = get_default_agent(llm=llm, cli_mode=True)
conversation = Conversation(agent=agent, workspace=workspace)
conversation.send_message(
    "In /workspace, create backend-ok.txt containing exactly the text "
    "runzivo-backend-ok, then use the finish action."
)
conversation.run()
result = workspace.execute_command("cat /workspace/backend-ok.txt")
print("result:", result.stdout.strip())
sys.exit(0 if "runzivo-backend-ok" in result.stdout else 1)
