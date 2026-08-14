```mermaid
graph TD
    User((🧑‍💻 用户)) -->|1. 下达特定领域任务| Agent

    subgraph AI 核心系统层
        Agent[🤖 Agent 智能体<br/>(核心大脑/调度执行者)]
        Skill[🧠 Skill 技能<br/>(专业领域知识包/工作流规范)]
        
        Agent -->|2a. 识别意图并加载| Skill
        Skill -->|2b. 提供Prompt约束与最佳实践| Agent
    end
    
    subgraph MCP 标准连接层
        MCP_Client[🔌 MCP Client<br/>(模型上下文协议客户端)]
        MCP_Server[⚙️ MCP Server<br/>(协议服务端/工具提供者)]
        
        Agent -->|3. 根据Skill指导决定调用工具| MCP_Client
        MCP_Client <-->|4. 统一的标准化通信| MCP_Server
    end
    
    subgraph 外部现实资源层
        MCP_Server -->|5. 读写操作| FS[📂 本地文件系统]
        MCP_Server -->|5. 查询/修改| DB[(🗄️ 数据库)]
        MCP_Server -->|5. 请求数据| API[🌐 外部网络 API]
    end

    %% 节点样式美化
    classDef agent fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:#000;
    classDef skill fill:#fff3e0,stroke:#ef6c00,stroke-width:2px,color:#000;
    classDef mcp fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,color:#000;
    classDef ext fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px,color:#000;

    class Agent agent;
    class Skill skill;
    class MCP_Client,MCP_Server mcp;
    class FS,DB,API ext;
```
