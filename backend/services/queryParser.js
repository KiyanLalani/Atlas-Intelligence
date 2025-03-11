const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Gemini API
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Constants for pattern matching
const EXAM_TYPES = ['GCSE', 'IGCSE', 'A-level', 'A level', 'Alevel', 'A Level'];
const EXAM_BOARDS = ['Edexcel', 'AQA', 'OCR', 'WJEC', 'Cambridge'];
const SUBJECTS = [
  'Mathematics', 'Maths', 'Math', 'Further Mathematics', 'Further Maths',
  'Biology', 'Chemistry', 'Physics', 'Combined Science', 'Science',
  'English', 'English Language', 'English Literature',
  'History', 'Geography', 'Religious Studies', 'RS',
  'Computer Science', 'Computing', 'ICT',
  'Business Studies', 'Economics', 'Sociology', 'Psychology',
  'French', 'German', 'Spanish', 'Latin',
  'Art', 'Music', 'Drama', 'Physical Education', 'PE'
];
const REQUEST_TYPES = [
  'notes', 'note', 'summary', 'explanation', 'explain',
  'past paper', 'past papers', 'pastpaper', 'pastpapers', 'exam paper', 'exam papers',
  'practice', 'practice questions', 'questions', 'exercise', 'exercises',
  'flashcard', 'flashcards', 'revision', 'revise'
];

/**
 * Parse a natural language query to extract structured parameters
 * @param {string} query - The natural language query from the user
 * @returns {Object} - Structured parameters extracted from the query
 */
async function parseQuery(query) {
  try {
    // First try pattern-based parsing for faster results
    const patternResults = patternBasedParsing(query);
    
    // If pattern-based parsing found all parameters, return them
    if (isCompleteParams(patternResults)) {
      return patternResults;
    }
    
    // Otherwise, use Gemini API for more advanced parsing
    const aiResults = await aiBasedParsing(query, patternResults);
    
    return aiResults;
  } catch (error) {
    console.error('Error parsing query:', error);
    // Return basic parsing results if AI parsing fails
    return patternBasedParsing(query);
  }
}

/**
 * Check if all parameters have been identified
 * @param {Object} params - The parameters object
 * @returns {boolean} - Whether all parameters are present
 */
function isCompleteParams(params) {
  return params.examType && params.examBoard && params.subject && params.topic && params.requestType;
}

/**
 * Use pattern matching to extract parameters from the query
 * @param {string} query - The natural language query
 * @returns {Object} - Extracted parameters
 */
function patternBasedParsing(query) {
  // Normalize the query
  const normalizedQuery = query.toLowerCase();
  
  // Initialize results
  const results = {
    examType: null,
    examBoard: null,
    subject: null,
    topic: null,
    requestType: null
  };
  
  // Extract exam type
  for (const examType of EXAM_TYPES) {
    if (normalizedQuery.includes(examType.toLowerCase())) {
      results.examType = examType.includes('GCSE') ? 'GCSE' : 
                         examType.includes('IGCSE') ? 'IGCSE' : 'A-level';
      break;
    }
  }
  
  // Extract exam board
  for (const board of EXAM_BOARDS) {
    if (normalizedQuery.includes(board.toLowerCase())) {
      results.examBoard = board;
      break;
    }
  }
  
  // Extract subject
  for (const subject of SUBJECTS) {
    if (normalizedQuery.includes(subject.toLowerCase())) {
      // Map to standardized subject names
      if (['math', 'maths', 'mathematics'].includes(subject.toLowerCase())) {
        results.subject = 'Mathematics';
      } else if (['english language', 'english lit'].includes(subject.toLowerCase())) {
        results.subject = subject;
      } else {
        results.subject = subject;
      }
      break;
    }
  }
  
  // Extract request type
  for (const type of REQUEST_TYPES) {
    if (normalizedQuery.includes(type.toLowerCase())) {
      // Map to standardized request types
      if (['notes', 'note', 'summary', 'explanation', 'explain'].includes(type.toLowerCase())) {
        results.requestType = 'notes';
      } else if (['past paper', 'past papers', 'pastpaper', 'pastpapers', 'exam paper', 'exam papers'].includes(type.toLowerCase())) {
        results.requestType = 'pastPaper';
      } else if (['practice', 'practice questions', 'questions', 'exercise', 'exercises'].includes(type.toLowerCase())) {
        results.requestType = 'practiceQuestions';
      } else {
        results.requestType = 'general';
      }
      break;
    }
  }
  
  // Extract topic (more complex, might need AI assistance)
  // This is a simple heuristic approach
  if (results.subject) {
    const subjectIndex = normalizedQuery.indexOf(results.subject.toLowerCase());
    if (subjectIndex !== -1) {
      // Look for topic after the subject mention
      const afterSubject = normalizedQuery.substring(subjectIndex + results.subject.length);
      
      // Look for phrases like "about", "on", "regarding", "topic of"
      const topicIndicators = ['about', 'on', 'regarding', 'topic of', 'topic', 'specifically'];
      for (const indicator of topicIndicators) {
        const indicatorIndex = afterSubject.indexOf(indicator);
        if (indicatorIndex !== -1) {
          // Extract the next few words as the topic
          const potentialTopic = afterSubject.substring(indicatorIndex + indicator.length).trim();
          // Take up to the next punctuation or end of string
          const endIndex = Math.min(
            ...['.', ',', '?', '!', 'for', 'with'].map(p => {
              const idx = potentialTopic.indexOf(p);
              return idx === -1 ? Infinity : idx;
            })
          );
          
          results.topic = potentialTopic.substring(0, endIndex === Infinity ? undefined : endIndex).trim();
          break;
        }
      }
    }
  }
  
  return results;
}

/**
 * Use Gemini API to extract parameters from the query
 * @param {string} query - The natural language query
 * @param {Object} patternResults - Results from pattern-based parsing
 * @returns {Object} - Enhanced extracted parameters
 */
async function aiBasedParsing(query, patternResults) {
  // Create a prompt for the Gemini model
  const prompt = `
  Parse the following educational query and extract these parameters:
  - Exam type (GCSE, IGCSE, A-level)
  - Exam board (Edexcel, AQA, OCR, WJEC, Cambridge)
  - Subject (e.g., Mathematics, Biology, Physics)
  - Topic (specific topic within the subject)
  - Request type (notes, pastPaper, practiceQuestions, general)
  
  Query: "${query}"
  
  Return ONLY a JSON object with these fields. If a parameter is not found, set it to null.
  `;

  // Get the Gemini model
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });
  
  // Generate content
  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();
  
  try {
    // Extract JSON from the response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsedJson = JSON.parse(jsonMatch[0]);
      
      // Merge with pattern results, preferring AI results when available
      return {
        examType: parsedJson.examType || patternResults.examType,
        examBoard: parsedJson.examBoard || patternResults.examBoard,
        subject: parsedJson.subject || patternResults.subject,
        topic: parsedJson.topic || patternResults.topic,
        requestType: parsedJson.requestType || patternResults.requestType
      };
    }
  } catch (error) {
    console.error('Error parsing AI response:', error);
  }
  
  // Fallback to pattern results if AI parsing fails
  return patternResults;
}

/**
 * Enhance the query with user preferences if parameters are missing
 * @param {Object} parsedQuery - The parsed query parameters
 * @param {Object} userPreferences - User preferences from their profile
 * @returns {Object} - Enhanced query parameters
 */
function enhanceWithUserPreferences(parsedQuery, userPreferences) {
  return {
    examType: parsedQuery.examType || userPreferences.examType || null,
    examBoard: parsedQuery.examBoard || userPreferences.examBoard || null,
    subject: parsedQuery.subject || (userPreferences.subjects && userPreferences.subjects[0]) || null,
    topic: parsedQuery.topic || null,
    requestType: parsedQuery.requestType || 'general'
  };
}

module.exports = {
  parseQuery,
  enhanceWithUserPreferences
}; 