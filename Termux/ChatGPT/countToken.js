const args = process.argv.slice(2);
//console.log(`接收到以下命令行参数：${args}`);

const { encode } = require('gpt-3-encoder');
const fs = require('fs');

// 要计算数量的文件路径
const filePath = args[0];

// 读取文件内容
const inputText = fs.readFileSync(filePath, { encoding: 'utf-8' });

// 将输入文本编码为token
const tokenizedText = encode(inputText);

// 计算token数量
const numTokens = tokenizedText.length;

// 计算characters数量
const numChars = inputText.length;

// 输出结果 TOKEN characters
console.log(`${numTokens} ${numChars}`);
