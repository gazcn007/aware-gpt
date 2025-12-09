//
//  OnboardingView.swift
//  AwareGPT
//
//  Created by AI Assistant on 2025-12-07.
//

import SwiftUI

struct OnboardingView: View {
  @Binding var isPresented: Bool
  @State private var currentPage = 0
  
  let pages: [OnboardingPage] = [
    OnboardingPage(
      image: "onboarding-1",
      title: "AI Without Limits",
      description: "Over 3 billion people lack reliable internet, yet they need AI's power. What if the world's most advanced language models could run entirely offline—right on your device?"
    ),
    OnboardingPage(
      image: "onboarding-2",
      title: "The Hidden Risk",
      description: "A teacher preparing lessons offline can't verify AI responses. When language models hallucinate, there's no warning—leaving educators and students vulnerable to misinformation."
    ),
    OnboardingPage(
      image: "onboarding-3",
      title: "Confidence at Your Fingertips",
      description: "ConfidentLM detects hallucinations in real-time, showing confidence scores for every response. Now you can trust AI with complete transparency—knowing exactly when to rely on each answer."
    )
  ]
  
  var body: some View {
    ZStack {
      // Background with blur
      Color(.systemBackground)
        .ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Skip button
        HStack {
          Spacer()
          Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              isPresented = false
            }
          }) {
            Text("Skip")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding(.horizontal, 20)
              .padding(.vertical, 10)
          }
        }
        .padding(.top, 20)
        .padding(.trailing, 20)
        
        // Page content
        TabView(selection: $currentPage) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            OnboardingPageView(page: page)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
        
        // Page indicator and buttons
        VStack(spacing: 24) {
          // Custom page indicator
          HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
              Capsule()
                .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: index == currentPage ? 24 : 8, height: 8)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
          }
          .padding(.top, 20)
          
          // Navigation buttons
          HStack(spacing: 16) {
            if currentPage > 0 {
              Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  currentPage -= 1
                }
              }) {
                Text("Back")
                  .font(.headline)
                  .foregroundColor(.secondary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 16)
                  .background(Color.secondary.opacity(0.1))
                  .cornerRadius(16)
              }
            }
            
            Button(action: {
              if currentPage < pages.count - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  currentPage += 1
                }
              } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                  isPresented = false
                }
              }
            }) {
              Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                  LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .cornerRadius(16)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 40)
        }
      }
    }
    .transition(.opacity.combined(with: .scale(scale: 0.95)))
  }
}

struct OnboardingPage {
  let image: String
  let title: String
  let description: String
}

struct OnboardingPageView: View {
  let page: OnboardingPage
  @State private var imageScale: CGFloat = 0.9
  @State private var imageOpacity: Double = 0
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      // Illustration
      Image(page.image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: 300)
        .scaleEffect(imageScale)
        .opacity(imageOpacity)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .onAppear {
          withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            imageScale = 1.0
            imageOpacity = 1.0
          }
        }
      
      // Text content
      VStack(spacing: 16) {
        Text(page.title)
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)
        
        Text(page.description)
          .font(.system(size: 17, weight: .regular))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .lineSpacing(4)
          .padding(.horizontal, 32)
      }
      .padding(.bottom, 40)
      
      Spacer()
    }
  }
}

#Preview {
  OnboardingView(isPresented: .constant(true))
}

