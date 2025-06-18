import { Link } from 'react-router-dom';

function Home() {
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-2xl mx-auto">
        <h1 className="text-4xl font-bold mb-4">Welcome Home</h1>
        <p className="text-gray-600 mb-6">
          This is your starting point for building amazing React applications. Our template includes everything you need to get started quickly.
        </p>
        <div className="flex space-x-4">
          <Link
            to="/about"
            className="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50"
          >
            Learn More
          </Link>
        </div>
      </div>
    </div>
  );
}

export default Home; 